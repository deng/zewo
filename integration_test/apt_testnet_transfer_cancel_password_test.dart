import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();

  testWidgets(
    'cancels apt testnet transfer at password prompt and stays on transfer page',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedAptTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddAptTestnetWallet(
        tester,
        walletName: 'APT Cancel',
        mnemonic: config.fundedAptTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'apt_testnet');

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'APT',
      );

      await openTransferFromWalletHome(tester);
      await expectAptTransferPage(tester);

      await fillAptTransferForm(
        tester,
        address: config.aptTestnetTransferRecipientAddress,
        amount: '0.0001',
      );
      await submitAptTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await cancelPasswordVerificationDialog(tester);

      await expectAptTransferPage(tester);
      expect(
        find.byKey(const Key('apt_transaction_status_page_title')),
        findsNothing,
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedAptTestnetWallet,
  );
}
