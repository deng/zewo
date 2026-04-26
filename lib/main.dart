import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zero_wallet/wallet.dart';

Future<void> main() async {
  await bootstrapZeroWalletApp();
}

Future<void> bootstrapZeroWalletApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 AppLifecycleManager
  await AppLifecycleManager.instance.initialize();

  runApp(const ZeroWalletApp());
}

class ZeroWalletApp extends StatefulWidget {
  const ZeroWalletApp({super.key});

  @override
  State<ZeroWalletApp> createState() => _ZeroWalletAppState();
}

class _ZeroWalletAppState extends State<ZeroWalletApp>
    with WidgetsBindingObserver {
  static const MethodChannel _deepLinkMethodChannel = MethodChannel(
    'zero/deep_links',
  );
  static const EventChannel _deepLinkEventChannel = EventChannel(
    'zero/deep_links/events',
  );
  static const _themeSeedColor = Color(0xFF3D6BFF);
  static const _lightScaffoldColor = Color(0xFFF4F7FB);
  static const _darkScaffoldColor = Color(0xFF0F131B);
  static const _themeRadius = 16.0;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final WalletProvider _walletProvider;
  late final WalletConnectController _walletConnectController;
  late final UsageSettingsController _usageSettingsController;
  late final SecuritySettingsController _securitySettingsController;
  late final AppLockController _appLockController;
  StreamSubscription<dynamic>? _deepLinkSubscription;
  String? _appliedLocalizationToken;
  bool _appLockDialogVisible = false;
  int _handledWalletConnectNavigationSerial = 0;

  late final ThemeData _lightTheme = _buildTheme(Brightness.light);

  late final ThemeData _darkTheme = _buildTheme(Brightness.dark);

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _themeSeedColor,
      brightness: brightness,
    );
    final scaffoldBackgroundColor = brightness == Brightness.dark
        ? _darkScaffoldColor
        : _lightScaffoldColor;
    final inputFillColor = brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow;

    OutlineInputBorder inputBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(_themeRadius),
        borderSide: BorderSide(color: color),
      );
    }

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      canvasColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        border: inputBorder(colorScheme.outlineVariant),
        enabledBorder: inputBorder(colorScheme.outlineVariant),
        disabledBorder: inputBorder(colorScheme.outlineVariant),
        focusedBorder: inputBorder(colorScheme.primary),
        errorBorder: inputBorder(colorScheme.error),
        focusedErrorBorder: inputBorder(colorScheme.error),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_themeRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_themeRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_themeRadius - 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _walletProvider = WalletProvider();
    _walletProvider.initialize();
    const walletConnectConfig = WalletConnectAppConfig(
      projectId: String.fromEnvironment(
        'WC_PROJECT_ID',
        defaultValue: '589379195ceab6e791dd510bf5feb122',
      ),
      redirectScheme: 'zerowallet',
      metadata: WalletConnectAppMetadata(
        name: 'Zero Wallet',
        description: 'Zero Wallet mobile app entry for WalletConnect flows.',
        url: 'https://github.com/deng/zero-wallet-dapp-connect',
        icons: <String>[
          'https://raw.githubusercontent.com/deng/zero-wallet-dapp-connect/main/assets/icon.png',
        ],
      ),
    );
    _walletConnectController = WalletConnectController(
      walletProvider: _walletProvider,
      config: walletConnectConfig,
      transportClient: walletConnectConfig.isConfigured
          ? ReownWalletConnectTransportClient()
          : const UnavailableWalletConnectTransportClient(
              reason:
                  'WalletConnect projectId is not configured. Rebuild with --dart-define=WC_PROJECT_ID=<your_project_id> to enable DApp connections.',
            ),
    );
    _walletConnectController.addListener(_handleWalletConnectChanged);
    _walletConnectController.initialize();
    _usageSettingsController = UsageSettingsController();
    _usageSettingsController.addListener(_handleUsageSettingsChanged);
    _usageSettingsController.initialize();
    _securitySettingsController = SecuritySettingsController();
    _securitySettingsController.initialize();
    _appLockController = AppLockController(
      securitySettingsController: _securitySettingsController,
      walletProvider: _walletProvider,
    );
    _appLockController.addListener(_handleAppLockChanged);
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    _walletConnectController.removeListener(_handleWalletConnectChanged);
    _appLockController.removeListener(_handleAppLockChanged);
    _usageSettingsController.removeListener(_handleUsageSettingsChanged);
    _walletConnectController.dispose();
    _appLockController.dispose();
    _securitySettingsController.dispose();
    _usageSettingsController.dispose();
    _walletProvider.dispose();
    // 在应用关闭时释放 AppLifecycleManager 的资源
    AppLifecycleManager.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_usageSettingsController.language == AppLanguage.system) {
      _syncWalletLocalization(_usageSettingsController.locale);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLockController.handleAppLifecycleState(state);
  }

  void _handleUsageSettingsChanged() {
    _syncWalletLocalization(_usageSettingsController.locale);
  }

  void _handleAppLockChanged() {
    if (_appLockController.isLocked) {
      _showAppLockDialogIfNeeded();
      return;
    }
    _dismissAppLockDialogIfNeeded();
  }

  Future<void> _listenForDeepLinks() async {
    try {
      final initialLink = await _deepLinkMethodChannel.invokeMethod<String>(
        'getInitialLink',
      );
      if (initialLink != null && initialLink.isNotEmpty) {
        await _walletConnectController.ingestPairingUri(
          initialLink,
          source: WalletConnectPairingSource.deepLink,
          navigateToHome: true,
        );
      }
    } catch (_) {}

    _deepLinkSubscription = _deepLinkEventChannel
        .receiveBroadcastStream()
        .listen((event) async {
          if (event is! String || event.isEmpty) {
            return;
          }
          await _walletConnectController.ingestPairingUri(
            event,
            source: WalletConnectPairingSource.deepLink,
            navigateToHome: true,
          );
        }, onError: (_) {});
  }

  void _handleWalletConnectChanged() {
    final target = _walletConnectController.navigationTarget;
    if (target == null ||
        target.serial <= _handledWalletConnectNavigationSerial) {
      return;
    }
    _handledWalletConnectNavigationSerial = target.serial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        return;
      }
      switch (target.destination) {
        case WalletConnectNavigationDestination.home:
          navigator.pushNamed(WalletRoutes.walletConnectHome);
          break;
        case WalletConnectNavigationDestination.proposalApproval:
          navigator.pushNamed(
            WalletRoutes.walletConnectProposalApproval,
            arguments: WalletConnectProposalApprovalRouteArgs(
              proposalId: target.proposalId!,
            ),
          );
          break;
        case WalletConnectNavigationDestination.requestApproval:
          navigator.pushNamed(
            WalletRoutes.walletConnectRequestApproval,
            arguments: WalletConnectRequestApprovalRouteArgs(
              requestId: target.requestId!,
            ),
          );
          break;
      }
      _walletConnectController.clearNavigationTarget(target.serial);
    });
  }

  void _showAppLockDialogIfNeeded() {
    if (!mounted) {
      return;
    }
    if (_appLockDialogVisible) {
      return;
    }
    final context = _navigatorKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showAppLockDialogIfNeeded();
      });
      return;
    }

    _appLockDialogVisible = true;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'app-lock',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, _, __) {
        return _AppLockDialog(controller: _appLockController);
      },
    ).whenComplete(() {
      if (!mounted) {
        return;
      }
      _appLockDialogVisible = false;
      if (_appLockController.isLocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _showAppLockDialogIfNeeded();
        });
      }
    });
  }

  void _dismissAppLockDialogIfNeeded() {
    if (!_appLockDialogVisible) {
      return;
    }
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) {
      return;
    }
    _appLockDialogVisible = false;
    navigator.pop();
  }

  void _syncWalletLocalization(Locale? locale) {
    final nextToken = _localizationToken(locale);
    if (_appliedLocalizationToken == nextToken) {
      return;
    }
    _appliedLocalizationToken = nextToken;
    WalletLocalizationManager.instance.setLocale(locale);
  }

  String _localizationToken(Locale? locale) {
    if (locale != null) {
      return locale.toLanguageTag();
    }
    return 'system:${WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag()}';
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 来自 wallet 库的 WalletProvider
        ChangeNotifierProvider<WalletProvider>.value(value: _walletProvider),
        ChangeNotifierProvider<WalletConnectController>.value(
          value: _walletConnectController,
        ),
        ChangeNotifierProvider<UsageSettingsController>.value(
          value: _usageSettingsController,
        ),
        ChangeNotifierProvider<SecuritySettingsController>.value(
          value: _securitySettingsController,
        ),
        ChangeNotifierProvider<AppLockController>.value(
          value: _appLockController,
        ),
      ],
      child:
          Selector<
            UsageSettingsController,
            ({ThemeMode themeMode, bool developerMode, Locale? locale})
          >(
            selector: (_, controller) => (
              themeMode: controller.themeMode,
              developerMode: controller.developerMode,
              locale: controller.locale,
            ),
            builder: (context, usageSettings, child) {
              return MaterialApp(
                navigatorKey: _navigatorKey,
                title: 'Zero Wallet',
                onGenerateRoute: WalletRoutes.onGenerateRoute,
                theme: _lightTheme,
                darkTheme: _darkTheme,
                themeMode: usageSettings.themeMode,
                locale: usageSettings.locale,
                supportedLocales: WalletLocalizations.supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) {
                  final content = child ?? const SizedBox.shrink();
                  return usageSettings.developerMode
                      ? Banner(
                          message: 'DEV',
                          location: BannerLocation.topEnd,
                          child: content,
                        )
                      : content;
                },
                home: const MainPage(),
              );
            },
          ),
    );
  }
}

class _AppLockDialog extends StatefulWidget {
  const _AppLockDialog({required this.controller});

  final AppLockController controller;

  @override
  State<_AppLockDialog> createState() => _AppLockDialogState();
}

class _AppLockDialogState extends State<_AppLockDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _didAttemptBiometricUnlock = false;
  String? _validationError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final l10n = context.l10n;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _validationError = l10n.appLockPasswordRequired;
      });
      return;
    }

    setState(() {
      _validationError = null;
    });
    final unlocked = await widget.controller.unlock(password);
    if (unlocked) {
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final errorText = _validationError ?? widget.controller.unlockError;
          final isBusy =
              widget.controller.isUnlocking ||
              widget.controller.isUnlockingWithBiometrics;

          if (!_didAttemptBiometricUnlock &&
              widget.controller.canUseBiometricUnlock) {
            _didAttemptBiometricUnlock = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.controller.isLocked) {
                _unlockWithBiometrics();
              }
            });
          }

          return Material(
            color: colorScheme.surface.withValues(alpha: 0.92),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  color: colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      key: const Key('app_lock_overlay'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.appLockTitle,
                          key: const Key('app_lock_title'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.controller.currentWalletName == null
                              ? l10n.appLockSubtitle
                              : '${widget.controller.currentWalletName}\n${l10n.appLockSubtitle}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          key: const Key('app_lock_password_field'),
                          controller: _passwordController,
                          enabled: !isBusy,
                          obscureText: !_passwordVisible,
                          onChanged: (_) {
                            if (_validationError != null) {
                              setState(() {
                                _validationError = null;
                              });
                            }
                            widget.controller.clearUnlockError();
                          },
                          decoration: InputDecoration(
                            labelText: l10n.appLockPasswordLabel,
                            errorText: errorText,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const Key('app_lock_unlock_button'),
                            onPressed: isBusy ? null : _unlock,
                            child: Text(
                              widget.controller.isUnlocking
                                  ? l10n.appLockUnlocking
                                  : l10n.appLockUnlock,
                            ),
                          ),
                        ),
                        if (widget.controller.canUseBiometricUnlock) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const Key('app_lock_biometric_button'),
                              onPressed: isBusy ? null : _unlockWithBiometrics,
                              icon: const Icon(Icons.fingerprint),
                              label: Text(l10n.appLockBiometricUnlock),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _validationError = null;
    });
    await widget.controller.unlockWithBiometrics();
  }
}
