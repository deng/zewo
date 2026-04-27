import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'cancels sol devnet transfer at password prompt and stays on transfer page',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedSolDevnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddSolDevnetWallet(
        tester,
        walletName: 'SOL Cancel',
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

      await fillSolTransferForm(
        tester,
        address: config.solDevnetTransferRecipientAddress,
        amount: config.solDevnetTransferAmount,
      );
      await submitSolTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await cancelPasswordVerificationDialog(tester);
      await expectSolTransferPage(tester);
      expect(find.text('SOL 转账状态'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedSolDevnetWallet,
  );
}
