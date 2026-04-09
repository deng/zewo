import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

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

  testWidgets('shows validation error for xrp testnet self transfer', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddXrpTestnetWallet(tester, walletName: 'XRP Self');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, 'xrp_testnet');

    await openTransferFromWalletHome(tester);
    await expectXrpTransferPage(tester);

    await fillXrpTransferForm(
      tester,
      address: currentWallet.defaultAddress!.address,
      amount: '1',
    );
    await submitXrpTransfer(tester);

    expectLatestToastMessage(toastMessages, '不能向当前 XRP 地址本身转账');
    await expectXrpTransferPage(tester);
  });
}
