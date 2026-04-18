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

  testWidgets('shows validation error for zero arbitrum sepolia amount', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddArbitrumTestnetWallet(
      tester,
      walletName: 'Arbitrum Zero',
    );

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, kArbitrumTestnetChainId);

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
