import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'stays on bch transfer page when password dialog is cancelled',
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
      await cancelPasswordVerificationDialog(tester);

      await expectBchTransferPage(tester);
      expect(find.text('BCH 交易状态'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedBchTestnetWallet,
  );
}
