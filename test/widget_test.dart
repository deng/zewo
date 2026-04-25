import 'package:bipx/bipx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';
import 'package:wallet/src/models/chain_models.dart';

class _FakeWalletProvider extends WalletProvider {
  _FakeWalletProvider(this._walletInfo);

  final WalletInfo? _walletInfo;

  @override
  bool get isLoading => false;

  @override
  WalletInfo? get currentWallet => _walletInfo;
}

void main() {
  testWidgets(
    'wallet MainPage builds without starting app-level background timers',
    (WidgetTester tester) async {
      final wallet = WalletInfo(
        id: 'wallet-1',
        name: 'Smoke Wallet',
        createdAt: DateTime.utc(2026, 1, 1),
        type: WalletType.mnemonic,
        chainType: ChainType.eth,
        networkType: NetworkType.mainnet,
        architectureType: BlockchainArchitecture.evm,
        chainId: '1',
        defaultAddressIndex: 0,
        mnemonicId: 'mnemonic-1',
      );
      wallet.updateDefaultAddress(
        CryptoAddress(
          id: 'address-1',
          address: '0x1234567890abcdef1234567890abcdef12345678',
          addressLower: '0x1234567890abcdef1234567890abcdef12345678',
          chainType: ChainType.eth,
          networkType: NetworkType.mainnet,
          architectureType: BlockchainArchitecture.evm,
          derivationMode: DerivationMode.mnemonic,
          accountIndex: 0,
          changeIndex: 0,
          addressIndex: 0,
          publicKey: '',
          path: '',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<WalletProvider>.value(
          value: _FakeWalletProvider(wallet),
          child: const MaterialApp(home: MainPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottom_nav_home')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_transaction')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_profile')), findsOneWidget);
    },
  );
}
