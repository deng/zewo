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

  testWidgets('shows validation error for invalid doge testnet address', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddDogeTestnetWallet(
      tester,
      walletName: 'DOGE TESTNET',
    );

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, kDogeTestnetChainId);

    await openTransferFromWalletHome(tester);
    await expectDogeTransferPage(tester);

    await fillDogeTransferForm(tester, address: 'invalid-address', amount: '1');
    await submitDogeTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 DOGE 地址');
    await expectDogeTransferPage(tester);
  });
}
