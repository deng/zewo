import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'cancels ton testnet transfer at password prompt and stays on transfer page',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedTonTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddTonTestnetWallet(
        tester,
        walletName: 'TON Cancel',
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

      await fillTonTransferForm(
        tester,
        address: config.tonTestnetTransferRecipientAddress,
        amount: config.tonTestnetTransferAmount,
      );
      await submitTonTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await cancelPasswordVerificationDialog(tester);
      await expectTonTransferPage(tester);
      expect(find.text('TON 交易结果'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedTonTestnetWallet,
  );
}
