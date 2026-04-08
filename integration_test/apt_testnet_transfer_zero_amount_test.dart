import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('shows validation when apt testnet transfer amount is zero', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddAptTestnetWallet(tester, walletName: 'APT Zero');
    await openTransferFromWalletHome(tester);
    await expectAptTransferPage(tester);

    await fillAptTransferForm(
      tester,
      address: kValidAptTransferAddress,
      amount: '0',
    );
    await submitAptTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的转账金额');
    await expectAptTransferPage(tester);
  });
}
