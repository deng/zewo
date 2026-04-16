import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'stays on ltc transfer page when password dialog is cancelled',
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
      await cancelPasswordVerificationDialog(tester);

      await expectLtcTransferPage(tester);
      expect(find.text('LTC 交易状态'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedLtcTestnetWallet,
  );
}
