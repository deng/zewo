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

  testWidgets('shows validation error for invalid sui address on testnet', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddSuiTestnetWallet(tester, walletName: 'SUI TESTNET');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, 'sui_testnet');

    await openTransferFromWalletHome(tester);
    await expectSuiTransferPage(tester);

    await fillSuiTransferForm(
      tester,
      address: 'invalid-address',
      amount: '0.01',
    );
    await submitSuiTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 Sui 地址');
    await expectSuiTransferPage(tester);
  });
}
