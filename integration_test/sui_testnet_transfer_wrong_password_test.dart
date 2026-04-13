import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();
  final toastMessages = <String>[];

  setUp(() async {
    await captureToastMessages(toastMessages);
  });

  tearDown(() async {
    await stopCapturingToastMessages();
  });

  testWidgets(
    'shows error for wrong password on sui testnet transfer',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedSuiTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddSuiTestnetWallet(
        tester,
        walletName: 'SUI Funded',
        mnemonic: config.fundedSuiTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'sui_testnet');

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'SUI',
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectSuiTransferPage(tester);

      await fillSuiTransferForm(
        tester,
        address: config.suiTestnetTransferRecipientAddress,
        amount: config.suiTestnetTransferAmount,
      );
      await submitSuiTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass123!');

      await waitForToastMessage(tester, toastMessages);
      expect(
        toastMessages.any((message) => message.contains('密码错误，请重试')),
        isTrue,
      );
      await expectSuiTransferPage(tester);
    },
    skip: walletConfig == null || !walletConfig.hasFundedSuiTestnetWallet,
  );
}
