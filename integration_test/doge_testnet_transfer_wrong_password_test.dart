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
    'shows error for wrong password on doge testnet transfer',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedDogeTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddDogeTestnetWallet(
        tester,
        walletName: 'DOGE Funded',
        mnemonic: config.fundedDogeTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kDogeTestnetChainId);

      await openTransferFromWalletHome(tester);
      await expectDogeTransferPage(tester);

      await fillDogeTransferForm(
        tester,
        address: config.dogeTestnetTransferRecipientAddress,
        amount: config.dogeTestnetTransferAmount,
      );
      await submitDogeTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass123!');

      await waitForToastMessageContaining(
        tester,
        toastMessages,
        message: '密码错误，请重试',
      );
      await expectDogeTransferPage(tester);
    },
    skip: walletConfig == null || !walletConfig.hasFundedDogeTestnetWallet,
  );
}
