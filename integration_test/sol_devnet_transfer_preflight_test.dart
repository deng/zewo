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

  testWidgets('shows validation error for invalid solana address on devnet', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddSolDevnetWallet(tester, walletName: 'SOL DEVNET');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, 'sol_devnet');

    await openTransferFromWalletHome(tester);
    await expectSolTransferPage(tester);

    await fillSolTransferForm(
      tester,
      address: 'invalid-address',
      amount: '0.01',
    );
    await submitSolTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 Solana 地址');
    await expectSolTransferPage(tester);
  });
}
