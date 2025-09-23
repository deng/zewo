# Zero - A Secure Flutter Crypto Wallet Application

Zero is a demonstration application built with Flutter that showcases the wallet package's capabilities for secure cryptocurrency wallet management.

## Features

- **Secure Wallet Creation**: Create new wallets with encrypted storage
- **Mnemonic Display**: Securely display mnemonic phrases with copy protection
- **Private Key Management**: Display and manage private keys with security warnings
- **Secure Storage**: All sensitive data is encrypted using `flutter_secure_storage`
- **Material Design**: Modern UI using Material 3 design system

## Architecture

Zero is built using the wallet package (`../wallet`) which provides:

- **Data Models**: `WalletInfo`, `MnemonicInfo`, `PrivateKeyInfo` 
- **Secure Storage**: `SecureStorageService` for encrypted persistence
- **UI Components**: `MnemonicDisplayWidget`, `PrivateKeyDisplayWidget`
- **Cryptographic Support**: Integration with `bipx` library

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Chrome browser (for web testing)

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run -d chrome    # For web
flutter run               # For mobile/desktop
```

3. Run tests:
```bash
flutter test
```

### Development

The application structure:
- `/lib/main.dart` - Main application entry point
- `/test/widget_test.dart` - Basic widget tests
- Dependencies on `../wallet` package for core functionality

## Usage

1. **First Launch**: App displays welcome screen
2. **Create Wallet**: Tap "Create New Wallet" to generate sample wallet data
3. **View Wallet Info**: See wallet metadata (name, type, creation date)
4. **View Sensitive Data**: 
   - Mnemonic phrase with word grid display
   - Private key with obscured text and copy functionality
5. **Delete Wallet**: Use delete button to remove wallet and all data

## Security Features

- All sensitive data encrypted at rest
- Mnemonic phrases displayed with security warnings
- Private keys obscured by default
- Copy protection with security notices
- Secure deletion of wallet data

## Package Dependencies

- `flutter`: Flutter framework
- `wallet`: Custom wallet management package (local dependency)
- Transitive dependencies:
  - `flutter_secure_storage`: Encrypted storage
  - `bipx`: Cryptographic operations

## Development Notes

This application serves as a testing and demonstration platform for the wallet package. The wallet data is generated with sample values for demonstration purposes.

## License

This project is part of the ZeroWallet workspace and follows the same licensing terms.
