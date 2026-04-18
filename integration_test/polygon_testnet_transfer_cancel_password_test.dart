import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

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
    'cancels polygon amoy transfer at password prompt and stays on transfer page',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedPolygonTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddPolygonTestnetWallet(
        tester,
        walletName: 'Polygon Cancel',
        mnemonic: config.fundedPolygonTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kPolygonTestnetChainId);

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'POL',
      );

      await openTransferFromWalletHome(tester);
      await expectEvmTransferPage(tester);

      toastMessages.clear();
      await fillEvmTransferForm(
        tester,
        address: config.polygonTestnetTransferRecipientAddress,
        amount: config.polygonTestnetTransferAmount,
      );
      await submitEvmTransfer(tester, waitForConfirmDialog: true);

      await expectEvmTransferConfirmDialog(tester);
      await confirmEvmTransferDialog(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await cancelPasswordVerificationDialog(tester);
      await waitForToastMessageValue(tester, toastMessages, message: '已取消交易');
      await expectEvmTransferPage(tester);
      expect(
        find.byKey(const Key('evm_transaction_status_page_title')),
        findsNothing,
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedPolygonTestnetWallet,
  );
}
