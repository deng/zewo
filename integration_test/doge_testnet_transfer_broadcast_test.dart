import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';
import 'package:zero_wallet/src/coins/doge/utils/doge_transaction_status_utils.dart';

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
    'broadcasts a real doge testnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedDogeTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddDogeTestnetWallet(
        tester,
        walletName: 'DOGE Funded',
        mnemonic: config.fundedDogeTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kDogeTestnetChainId);
      expect(
        currentWallet.defaultAddress?.address,
        config.fundedDogeTestnetAddress,
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZeroForChain(
        tester,
        chainId: kDogeTestnetChainId,
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectDogeTransferPage(tester);

      await fillDogeTransferForm(
        tester,
        address: config.dogeTestnetTransferRecipientAddress,
        amount: config.dogeTestnetTransferAmount,
      );
      await submitDogeTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectDogeTransactionStatusPage(
        tester,
        timeout: const Duration(minutes: 2),
      );
      await waitForDogeTransactionBroadcastedOrConfirmed(tester);

      final txHash = await readDogeTransactionHash(tester);
      expect(RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(txHash), isTrue);

      await openDogeExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        DogeTransactionStatusUtils.explorerUrl(
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
    skip: walletConfig == null || !walletConfig.hasFundedDogeTestnetWallet,
  );
}
