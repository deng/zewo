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

  testWidgets('shows validation error for zero eth sepolia amount', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddEthSepoliaWallet(tester, walletName: 'ETH Zero');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, '11155111');

    await openTransferFromWalletHome(tester);
    await expectEvmTransferPage(tester);

    await fillEvmTransferForm(
      tester,
      address: kValidEvmTransferAddress,
      amount: '0',
    );
    await submitEvmTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效金额');
    await expectEvmTransferPage(tester);
  });
}
