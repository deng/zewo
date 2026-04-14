import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'stays on btc transfer page when password dialog is cancelled',
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
      await cancelPasswordVerificationDialog(tester);

      await expectBtcTransferPage(tester);
      expect(find.text('BTC 交易状态'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedBtcTestnetWallet,
  );
}
