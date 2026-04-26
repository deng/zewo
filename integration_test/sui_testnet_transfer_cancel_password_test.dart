import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'stays on sui transfer page when password dialog is cancelled',
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
      await cancelPasswordVerificationDialog(tester);

      await expectSuiTransferPage(tester);
      expect(find.text('SUI 转账状态'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedSuiTestnetWallet,
  );
}
