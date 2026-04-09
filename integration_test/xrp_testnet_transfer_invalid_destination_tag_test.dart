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

  testWidgets('shows validation error for invalid xrp destination tag', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddXrpTestnetWallet(tester, walletName: 'XRP Tag');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, 'xrp_testnet');

    await openTransferFromWalletHome(tester);
    await expectXrpTransferPage(tester);

    await fillXrpTransferForm(
      tester,
      address: kValidXrpTransferAddress,
      amount: '1',
      destinationTag: 'abc',
    );
    await submitXrpTransfer(tester);

    expectLatestToastMessage(toastMessages, 'Destination Tag 格式无效');
    await expectXrpTransferPage(tester);
  });
}
