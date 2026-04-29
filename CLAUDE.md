# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zero is a thin Flutter app shell that consumes the `zero_wallet` package (`../wallet`). It contains no business logic — everything (wallet management, blockchain RPC, UI pages, WalletConnect) lives in the wallet package.

## Build & Test Commands

All commands run from the `zero/` directory.

```bash
# Get dependencies
flutter pub get

# Run unit + widget tests (test/)
flutter test
# Single test file
flutter test test/widget_test.dart

# Run integration tests (integration_test/)
flutter test integration_test/
# Single integration test
flutter test integration_test/app_smoke_test.dart
# With test wallet config (for funded wallet tests)
./tool/flutter_integration_test_no_proxy.sh

# Analyze / lint
flutter analyze

# Run app
flutter run -d chrome    # web
flutter run              # mobile/desktop
# With WalletConnect project ID
flutter run --dart-define=WC_PROJECT_ID=<your_project_id>

# Build APK
flutter build apk --debug
# Or use convenience script
./apk.sh
```

**Proxy note:** In environments with restricted network access, use wrapper scripts in `tool/` which unset proxy env vars and set Chinese Flutter mirrors. Unit tests also need proxy unset to avoid test harness handshake failure:
```bash
env -u http_proxy -u https_proxy flutter test
```

## Architecture

`lib/main.dart` is the only source file. It bootstraps the wallet package and sets up the app shell:

```
main()
  -> bootstrapZeroWalletApp()
       -> WidgetsFlutterBinding.ensureInitialized()
       -> AppLifecycleManager.instance.initialize()
       -> runApp(ZeroWalletApp)
```

**ZeroWalletApp** (StatefulWidget + WidgetsBindingObserver) orchestrates:

- **Theme**: Material 3 from `ColorScheme.fromSeed(seedColor: 0xFF3D6BFF)`, light/dark support
- **State Management**: MultiProvider providing controllers from the wallet package:
  - `WalletProvider` — wallet data/state
  - `WalletConnectController` — DApp connections (WalletConnect/Reown)
  - `UsageSettingsController` — theme mode, language, developer mode
  - `SecuritySettingsController` — security preferences
  - `AppLockController` — password/biometric app lock
- **Routing**: `WalletRoutes.onGenerateRoute` from the wallet package
- **Deep Links**: MethodChannel `zero/deep_links` + EventChannel `zero/deep_links/events` for WalletConnect URI ingestion
- **Home**: `MainPage()` from the wallet package

## Key Patterns

- **App Lock**: Full-screen modal overlay (`_AppLockDialog`) triggered by `AppLockController.isLocked`. Attempts biometric unlock on first appearance, falls back to password. Cannot be dismissed via back button.
- **Deep Links**: Single-shot initial link via invokeMethod, then continuous stream subscription. Deduplicated via `_consumedInitialDeepLink` field.
- **Localization**: `WalletLocalizationManager` syncs locale from `UsageSettingsController`. System-language mode reacts to `didChangeLocales`.
- **WalletConnect Navigation**: `WalletConnectController.navigationTarget` drives routed navigation (home, proposal approval, request approval) with serial-based dedup.

## Test Structure

- **`test/`** — 2 widget/unit test files. `widget_test.dart` renders MainPage with empty WalletProvider and asserts bottom nav. `test_wallet_config_test.dart` tests integration test wallet config loading.
- **`integration_test/`** — 100+ files organized by feature:
  - Wallet management (create/import/backup validation)
  - Chain transfer tests (16 chains, each with preflight, broadcast, wrong-password, cancel-password, zero-amount, self-transfer, insufficient-balance scenarios)
  - Profile/settings flow tests
  - `test_helpers.dart` — shared helpers: test app bootstrap, UI interaction utilities (pumpUntilVisible, tapAndPump), chain-specific wallet creation, transaction status waiters
  - `test_wallet_config.dart` — contract for loading funded test wallet configs from dart-define or local JSON file
  - `.test_wallet_config.json` (gitignored) — actual funded test wallet mnemonics

## Dependencies

- `zero_wallet` (path: `../wallet`) — core wallet library providing all business logic, UI, and blockchain integration
- `provider: ^6.0.5` — state management (ChangeNotifierProvider)
- `flutter_inappwebview: ^6.1.5` — WebView for dApp browser (used by wallet package)
- `flutter_lints: ^5.0.0` (dev) — lint rules from `package:flutter_lints/flutter.yaml`
