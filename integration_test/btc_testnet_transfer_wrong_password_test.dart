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
    'shows error for wrong password on btc testnet transfer',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedBtcTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddBtcTestnetWallet(
        tester,
        walletName: 'BTC Funded',
        mnemonic: config.fundedBtcTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kBtcTestnetChainId);

      await openTransferFromWalletHome(tester);
      await expectBtcTransferPage(tester);

      await fillBtcTransferForm(
        tester,
        address: config.btcTestnetTransferRecipientAddress,
        amount: config.btcTestnetTransferAmount,
      );
      await submitBtcTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass123!');

      await waitForToastMessageContaining(
        tester,
        toastMessages,
        message: '密码错误，请重试',
      );
      await expectBtcTransferPage(tester);
    },
    skip: walletConfig == null || !walletConfig.hasFundedBtcTestnetWallet,
  );
}
