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
    'broadcasts a real ton testnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedTonTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddTonTestnetWallet(
        tester,
        walletName: 'TON Funded',
        mnemonic: config.fundedTonTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'ton_testnet');
      expect(
        currentWallet.defaultAddress?.address,
        config.fundedTonTestnetAddress,
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'TON',
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectTonTransferPage(tester);

      await fillTonTransferForm(
        tester,
        address: config.tonTestnetTransferRecipientAddress,
        amount: config.tonTestnetTransferAmount,
      );
      await submitTonTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectTonTransactionStatusPage(
        tester,
        timeout: const Duration(minutes: 2),
      );
      await waitForTonTransactionConfirmed(tester);

      final lookupHash = await readTonTransactionLookupHash(tester);
      expect(lookupHash, isNotEmpty);

      await openTonExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        'https://testnet.tonviewer.com/transaction/$lookupHash',
      );

      await returnToWalletHomeFromStatusPage(tester);
      await pumpUntilVisible(
        tester,
        find.byKey(const Key('wallet_home_selector_button')),
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedTonTestnetWallet,
  );
}
