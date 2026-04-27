import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'stays on doge transfer page when password dialog is cancelled',
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
      await cancelPasswordVerificationDialog(tester);

      await expectDogeTransferPage(tester);
      expect(find.text('DOGE 交易状态'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedDogeTestnetWallet,
  );
}
