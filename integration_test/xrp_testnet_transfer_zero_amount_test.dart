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

  testWidgets('shows validation error for zero xrp testnet amount', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddXrpTestnetWallet(tester, walletName: 'XRP Zero');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, 'xrp_testnet');

    await openTransferFromWalletHome(tester);
    await expectXrpTransferPage(tester);

    await fillXrpTransferForm(
      tester,
      address: kValidXrpTransferAddress,
      amount: '0',
    );
    await submitXrpTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的转账金额');
    await expectXrpTransferPage(tester);
  });
}
