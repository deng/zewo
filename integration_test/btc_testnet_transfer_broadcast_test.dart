import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';
import 'package:zero_wallet/src/coins/btc/utils/btc_transaction_status_utils.dart';

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
    'broadcasts a real btc testnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedBtcTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddBtcTestnetWallet(
        tester,
        walletName: 'BTC Funded',
        mnemonic: config.fundedBtcTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kBtcTestnetChainId);
      expect(
        currentWallet.defaultAddress?.address,
        config.fundedBtcTestnetAddress,
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZeroForChain(
        tester,
        chainId: kBtcTestnetChainId,
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectBtcTransferPage(tester);

      await fillBtcTransferForm(
        tester,
        address: config.btcTestnetTransferRecipientAddress,
        amount: config.btcTestnetTransferAmount,
      );
      await submitBtcTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectBtcTransactionStatusPage(
        tester,
        timeout: const Duration(minutes: 2),
      );
      await waitForBtcTransactionBroadcastedOrConfirmed(tester);

      final txHash = await readBtcTransactionHash(tester);
      expect(RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(txHash), isTrue);

      await openBtcExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        BTCTransactionStatusUtils.explorerUrl(
          txHash: txHash,
          isMainnet: false,
        ),
      );

      await returnToWalletHomeFromStatusPage(tester);
      await pumpUntilVisible(
        tester,
        find.byKey(const Key('wallet_home_selector_button')),
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedBtcTestnetWallet,
  );
}
