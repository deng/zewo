import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';
import 'package:zero_wallet/src/coins/bch/utils/bch_transaction_status_utils.dart';

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
    'broadcasts a real bch chipnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedBchTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddBchTestnetWallet(
        tester,
        walletName: 'BCH Funded',
        mnemonic: config.fundedBchTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kBchTestnetChainId);
      expect(
        currentWallet.defaultAddress?.address,
        config.fundedBchTestnetAddress,
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZeroForChain(
        tester,
        chainId: kBchTestnetChainId,
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectBchTransferPage(tester);

      await fillBchTransferForm(
        tester,
        address: config.bchTestnetTransferRecipientAddress,
        amount: config.bchTestnetTransferAmount,
      );
      await submitBchTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectBchTransactionStatusPage(
        tester,
        timeout: const Duration(minutes: 2),
      );
      await waitForBchTransactionBroadcastedOrConfirmed(tester);

      final txHash = await readBchTransactionHash(tester);
      expect(RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(txHash), isTrue);

      await openBchExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        BchTransactionStatusUtils.explorerUrl(
          txid: txHash,
          networkType: currentWallet.networkType,
        ),
      );

      await returnToWalletHomeFromStatusPage(tester);
      await pumpUntilVisible(
        tester,
        find.byKey(const Key('wallet_home_selector_button')),
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedBchTestnetWallet,
  );
}
