import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

Future<void> _waitForToastMessage(
  WidgetTester tester,
  List<String> toastMessages, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (toastMessages.isNotEmpty) {
      return;
    }
    await tester.pump(step);
  }

  throw TestFailure('Timed out waiting for XRP transfer error toast');
}

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
    'rejects xrp testnet transfer when password is wrong',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedXrpTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddXrpTestnetWallet(
        tester,
        walletName: 'XRP Wrong',
        mnemonic: config.fundedXrpTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'xrp_testnet');

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'XRP',
      );

      await openTransferFromWalletHome(tester);
      await expectXrpTransferPage(tester);

      toastMessages.clear();
      await fillXrpTransferForm(
        tester,
        address: config.xrpTestnetTransferRecipientAddress,
        amount: config.xrpTestnetTransferAmount,
        destinationTag: config.xrpTestnetTransferDestinationTagOrNull,
      );
      await submitXrpTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester, password: 'WrongPass1!');

      await _waitForToastMessage(tester, toastMessages);

      expectLatestToastMessage(toastMessages, '密码错误，请重试');
      await expectXrpTransferPage(tester);
      expect(
        find.byKey(const Key('xrp_transaction_status_page_title')),
        findsNothing,
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedXrpTestnetWallet,
  );
}
