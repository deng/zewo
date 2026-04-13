import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();
  final launchedUrls = <String>[];

  setUp(() async {
    await captureExternalLaunchUrls(launchedUrls);
  });

  tearDown(() async {
    await stopCapturingExternalLaunchUrls();
  });

  testWidgets(
    'broadcasts a real sui testnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedSuiTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddSuiTestnetWallet(
        tester,
        walletName: 'SUI Funded',
        mnemonic: config.fundedSuiTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'sui_testnet');
      expect(
        currentWallet.defaultAddress?.address,
        config.fundedSuiTestnetAddress,
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'SUI',
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectSuiTransferPage(tester);

      await fillSuiTransferForm(
        tester,
        address: config.suiTestnetTransferRecipientAddress,
        amount: config.suiTestnetTransferAmount,
      );
      await submitSuiTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectSuiTransactionStatusPage(
        tester,
        timeout: const Duration(minutes: 2),
      );
      await waitForSuiTransactionConfirmed(tester);

      final digest = await readSuiTransactionDigest(tester);
      expect(
        RegExp(
          r'^(0x[0-9a-fA-F]{64}|[1-9A-HJ-NP-Za-km-z]{20,})$',
        ).hasMatch(digest),
        isTrue,
      );

      await openSuiExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        'https://testnet.suivision.xyz/txblock/$digest',
      );

      await returnToWalletHomeFromStatusPage(tester);
      await pumpUntilVisible(
        tester,
        find.byKey(const Key('wallet_home_selector_button')),
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedSuiTestnetWallet,
  );
}
