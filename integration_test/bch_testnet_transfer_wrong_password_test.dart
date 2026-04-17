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
    'shows error for wrong password on bch chipnet transfer',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedBchTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddBchTestnetWallet(
        tester,
        walletName: 'BCH Funded',
        mnemonic: config.fundedBchTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kBchTestnetChainId);

      await openTransferFromWalletHome(tester);
      await expectBchTransferPage(tester);

      await fillBchTransferForm(
        tester,
        address: config.bchTestnetTransferRecipientAddress,
        amount: config.bchTestnetTransferAmount,
      );
      await submitBchTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass123!');

      await waitForToastMessageContaining(
        tester,
        toastMessages,
        message: '密码错误，请重试',
      );
      await expectBchTransferPage(tester);
    },
    skip: walletConfig == null || !walletConfig.hasFundedBchTestnetWallet,
  );
}
