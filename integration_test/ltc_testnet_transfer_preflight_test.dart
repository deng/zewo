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

  testWidgets('shows validation error for invalid ltc address on testnet', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddLtcTestnetWallet(tester, walletName: 'LTC TESTNET');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, kLtcTestnetChainId);

    await openTransferFromWalletHome(tester);
    await expectLtcTransferPage(tester);

    await fillLtcTransferForm(
      tester,
      address: 'invalid-address',
      amount: '0.001',
    );
    await submitLtcTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 LTC 地址');
    await expectLtcTransferPage(tester);
  });
}
