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
    'rejects sol devnet transfer when password is wrong',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedSolDevnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddSolDevnetWallet(
        tester,
        walletName: 'SOL Wrong',
        mnemonic: config.fundedSolDevnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'sol_devnet');

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'SOL',
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectSolTransferPage(tester);

      toastMessages.clear();
      await fillSolTransferForm(
        tester,
        address: config.solDevnetTransferRecipientAddress,
        amount: config.solDevnetTransferAmount,
      );
      await submitSolTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass1!');
      await waitForToastMessage(tester, toastMessages);
      expect(
        toastMessages.any((message) => message.contains('密码错误，请重试')),
        isTrue,
      );
      await expectSolTransferPage(tester);
      expect(find.text('SOL 转账状态'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedSolDevnetWallet,
  );
}
