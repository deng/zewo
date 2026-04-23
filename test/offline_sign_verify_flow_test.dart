import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

import 'package:zero/offline_sign_verify/evm_offline_sign_page.dart';
import 'package:zero/offline_sign_verify/evm_offline_verify_page.dart';

class _FakeWalletProvider extends WalletProvider {
  _FakeWalletProvider(this._walletInfo);

  final WalletInfo _walletInfo;

  @override
  bool get isLoading => false;

  @override
  WalletInfo? get currentWallet => _walletInfo;
}

class _FakeOfflineSignVerifyService extends OfflineSignVerifyService {
  _FakeOfflineSignVerifyService();

  static const signature = '0xdeadbeef';
  static const digest = '0xfeedface';
  static const address = '0x1234567890abcdef1234567890abcdef12345678';

  @override
  Future<SignPayloadResult> sign(
    SignPayloadRequest request, {
    required String password,
  }) async {
    return SignPayloadResult(
      signingStandard: request.signingStandard,
      payloadType: request.payloadType,
      signature: signature,
      signatureEncoding: request.signatureEncoding,
      digest: digest,
      digestEncoding: PayloadEncoding.hex,
      resolvedSignerAddress: address,
    );
  }

  @override
  Future<VerifyPayloadResult> verify(VerifyPayloadRequest request) async {
    return VerifyPayloadResult(
      signatureValid: request.signature == signature,
      signerMatched:
          request.expectedSignerAddress == null ||
          request.expectedSignerAddress == address,
      resolvedSignerAddress: address,
      resolvedSignerPublicKey: '0xabc',
      digest: digest,
      digestEncoding: PayloadEncoding.hex,
    );
  }
}

void main() {
  testWidgets('EVM offline sign and verify pages form a closed loop', (
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
        address: _FakeOfflineSignVerifyService.address,
        addressLower: _FakeOfflineSignVerifyService.address,
        chainType: ChainType.eth,
        networkType: NetworkType.mainnet,
        architectureType: BlockchainArchitecture.evm,
        derivationMode: DerivationMode.mnemonic,
        accountIndex: 0,
        changeIndex: 0,
        addressIndex: 0,
        publicKey: '0xabc',
        path: "m/44'/60'/0'/0/0",
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final provider = _FakeWalletProvider(wallet);
    final service = _FakeOfflineSignVerifyService();

    await tester.pumpWidget(
      ChangeNotifierProvider<WalletProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold()),
      ),
    );

    final rootContext = tester.element(find.byType(Scaffold));

    Navigator.of(rootContext).push(
      MaterialPageRoute<void>(
        builder: (_) => EvmOfflineSignPage(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('evm_offline_sign_payload_field')),
      'hello evm',
    );
    await tester.enterText(
      find.byKey(const Key('evm_offline_sign_password_field')),
      'password',
    );
    await tester.tap(find.byKey(const Key('evm_offline_sign_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('签名结果'), findsOneWidget);
    expect(find.text(_FakeOfflineSignVerifyService.signature), findsOneWidget);

    Navigator.of(tester.element(find.text('签名结果'))).pop();
    await tester.pumpAndSettle();

    Navigator.of(rootContext).push(
      MaterialPageRoute<void>(
        builder: (_) => EvmOfflineVerifyPage(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('evm_offline_verify_payload_field')),
      'hello evm',
    );
    await tester.enterText(
      find.byKey(const Key('evm_offline_verify_signature_field')),
      _FakeOfflineSignVerifyService.signature,
    );
    await tester.enterText(
      find.byKey(const Key('evm_offline_verify_expected_address_field')),
      _FakeOfflineSignVerifyService.address,
    );
    await tester.tap(find.byKey(const Key('evm_offline_verify_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('验签结果'), findsOneWidget);
    expect(find.text('true'), findsWidgets);
    expect(find.text(_FakeOfflineSignVerifyService.address), findsOneWidget);
  });
}
