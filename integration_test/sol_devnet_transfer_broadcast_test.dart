import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'broadcasts a real sol devnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedSolDevnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddSolDevnetWallet(
        tester,
        walletName: 'SOL Funded',
        mnemonic: config.fundedSolDevnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'sol_devnet');
      expect(
        currentWallet.defaultAddress?.address,
        config.fundedSolDevnetAddress,
      );

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
      await unlockPasswordPrompt(tester);

      await expectSolTransactionStatusPage(
        tester,
        timeout: const Duration(minutes: 2),
      );
      await waitForSolTransactionConfirmed(tester);

      final signature = await readSolTransactionSignature(tester);
      expect(
        RegExp(r'^[1-9A-HJ-NP-Za-km-z]{80,100}$').hasMatch(signature),
        isTrue,
      );

      await returnToWalletHomeFromStatusPage(tester);
      await pumpUntilVisible(
        tester,
        find.byKey(const Key('wallet_home_selector_button')),
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedSolDevnetWallet,
  );
}
