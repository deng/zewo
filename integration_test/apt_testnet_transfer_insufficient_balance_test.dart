import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

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
    'shows validation when apt testnet transfer amount exceeds balance',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedAptTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddAptTestnetWallet(
        tester,
        walletName: 'APT Balance',
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
        amount: '999999',
      );
      await submitAptTransfer(tester);

      expectLatestToastMessage(toastMessages, 'APT 余额不足');
      await expectAptTransferPage(tester);
      expect(
        find.byKey(const Key('password_verification_field')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('apt_transaction_status_page_title')),
        findsNothing,
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedAptTestnetWallet,
  );
}
