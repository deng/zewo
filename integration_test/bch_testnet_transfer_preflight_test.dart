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

  testWidgets('shows validation error for invalid bch address on chipnet', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddBchTestnetWallet(tester, walletName: 'BCH CHIPNET');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, kBchTestnetChainId);

    await openTransferFromWalletHome(tester);
    await expectBchTransferPage(tester);

    await fillBchTransferForm(
      tester,
      address: 'invalid-address',
      amount: '0.001',
    );
    await submitBchTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 BCH 地址');
    await expectBchTransferPage(tester);
  });
}
