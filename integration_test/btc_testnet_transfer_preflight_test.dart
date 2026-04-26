import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  final toastMessages = <String>[];

  setUp(() async {
    await captureToastMessages(toastMessages);
  });

  tearDown(() async {
    await stopCapturingToastMessages();
  });

  testWidgets('shows validation error for invalid btc address on testnet', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddBtcTestnetWallet(tester, walletName: 'BTC TESTNET');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, kBtcTestnetChainId);

    await openTransferFromWalletHome(tester);
    await expectBtcTransferPage(tester);

    await fillBtcTransferForm(
      tester,
      address: 'invalid-address',
      amount: '0.0001',
    );
    await submitBtcTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 BTC 地址');
    await expectBtcTransferPage(tester);
  });
}
