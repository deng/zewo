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

  testWidgets('shows validation error for invalid ton address on testnet', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddTonTestnetWallet(tester, walletName: 'TON TESTNET');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, 'ton_testnet');

    await openTransferFromWalletHome(tester);
    await expectTonTransferPage(tester);

    await fillTonTransferForm(
      tester,
      address: 'invalid-address',
      amount: '0.05',
    );
    await submitTonTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 TON 地址');
    await expectTonTransferPage(tester);
  });
}
