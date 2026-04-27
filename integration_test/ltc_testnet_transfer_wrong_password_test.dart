import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

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
    'shows error for wrong password on ltc testnet transfer',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedLtcTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddLtcTestnetWallet(
        tester,
        walletName: 'LTC Funded',
        mnemonic: config.fundedLtcTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kLtcTestnetChainId);

      await openTransferFromWalletHome(tester);
      await expectLtcTransferPage(tester);

      await fillLtcTransferForm(
        tester,
        address: config.ltcTestnetTransferRecipientAddress,
        amount: config.ltcTestnetTransferAmount,
      );
      await submitLtcTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass123!');

      await waitForToastMessageContaining(
        tester,
        toastMessages,
        message: '密码错误，请重试',
      );
      await expectLtcTransferPage(tester);
    },
    skip: walletConfig == null || !walletConfig.hasFundedLtcTestnetWallet,
  );
}
