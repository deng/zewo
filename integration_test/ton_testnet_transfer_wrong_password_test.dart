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
    'rejects ton testnet transfer when password is wrong',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedTonTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddTonTestnetWallet(
        tester,
        walletName: 'TON Wrong',
        mnemonic: config.fundedTonTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'ton_testnet');

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'TON',
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectTonTransferPage(tester);

      toastMessages.clear();
      await fillTonTransferForm(
        tester,
        address: config.tonTestnetTransferRecipientAddress,
        amount: config.tonTestnetTransferAmount,
      );
      await submitTonTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass1!');
      await waitForToastMessage(tester, toastMessages);
      expect(
        toastMessages.any((message) => message.contains('密码错误，请重试')),
        isTrue,
      );
      await expectTonTransferPage(tester);
      expect(find.text('TON 交易结果'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedTonTestnetWallet,
  );
}
