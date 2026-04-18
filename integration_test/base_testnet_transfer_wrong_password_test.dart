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
    'rejects base sepolia transfer when password is wrong',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedBaseTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddBaseTestnetWallet(
        tester,
        walletName: 'Base Wrong',
        mnemonic: config.fundedBaseTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kBaseTestnetChainId);

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'ETH',
      );

      await openTransferFromWalletHome(tester);
      await expectEvmTransferPage(tester);

      toastMessages.clear();
      await fillEvmTransferForm(
        tester,
        address: config.baseTestnetTransferRecipientAddress,
        amount: config.baseTestnetTransferAmount,
      );
      await submitEvmTransfer(tester, waitForConfirmDialog: true);

      await expectEvmTransferConfirmDialog(tester);
      await confirmEvmTransferDialog(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass1!');
      await waitForToastMessageValue(
        tester,
        toastMessages,
        message: '密码错误，请重试',
      );
      await expectEvmTransferPage(tester);
      expect(
        find.byKey(const Key('evm_transaction_status_page_title')),
        findsNothing,
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedBaseTestnetWallet,
  );
}
