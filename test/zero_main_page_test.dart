import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

import 'package:zero/zero_main_page.dart';

class _FakeWalletProvider extends WalletProvider {
  _FakeWalletProvider(this._walletInfo);

  final WalletInfo? _walletInfo;

  @override
  bool get isLoading => false;

  @override
  WalletInfo? get currentWallet => _walletInfo;
}

void main() {
  testWidgets('ZeroMainPage transaction tab shows wallet OfflineToolsPage', (
    WidgetTester tester,
  ) async {
    final wallet = WalletInfo(
      id: 'wallet-1',
      name: 'EVM Wallet',
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
        child: const MaterialApp(home: ZeroMainPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bottom_nav_transaction')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom_nav_transaction')));
    await tester.pumpAndSettle();

    expect(find.text('签名工具'), findsOneWidget);
    expect(find.text('离线签名'), findsOneWidget);
  });

  testWidgets(
    'ZeroMainPage transaction tab shows wallet OfflineToolsPage for non-EVM wallet',
    (WidgetTester tester) async {
      final wallet = WalletInfo(
        id: 'wallet-2',
        name: 'SOL Wallet',
        createdAt: DateTime.utc(2026, 1, 1),
        type: WalletType.mnemonic,
        chainType: ChainType.sol,
        networkType: NetworkType.mainnet,
        architectureType: BlockchainArchitecture.solana,
        chainId: 'sol-mainnet',
        defaultAddressIndex: 0,
        mnemonicId: 'mnemonic-2',
      );
      wallet.updateDefaultAddress(
        CryptoAddress(
          id: 'address-2',
          address: 'So11111111111111111111111111111111111111112',
          addressLower: 'so11111111111111111111111111111111111111112',
          chainType: ChainType.sol,
          networkType: NetworkType.mainnet,
          architectureType: BlockchainArchitecture.solana,
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
          child: const MaterialApp(home: ZeroMainPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_transaction')));
      await tester.pumpAndSettle();

      expect(find.text('签名工具'), findsOneWidget);
      expect(find.text('SOL 验签'), findsOneWidget);
    },
  );
}
