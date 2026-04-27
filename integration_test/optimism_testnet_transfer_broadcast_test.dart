import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

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
    'broadcasts a real optimism sepolia transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedOptimismTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddOptimismTestnetWallet(
        tester,
        walletName: 'Optimism Funded',
        mnemonic: config.fundedOptimismTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kOptimismTestnetChainId);
      expect(
        currentWallet.defaultAddress?.address.toLowerCase(),
        config.fundedOptimismTestnetAddress.toLowerCase(),
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'ETH',
      );

      await openTransferFromWalletHome(tester);
      await expectEvmTransferPage(tester);

      await fillEvmTransferForm(
        tester,
        address: config.optimismTestnetTransferRecipientAddress,
        amount: config.optimismTestnetTransferAmount,
      );
      await submitEvmTransfer(tester, waitForConfirmDialog: true);

      await expectEvmTransferConfirmDialog(tester);
      await confirmEvmTransferDialog(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectEvmTransactionStatusPage(tester);
      await waitForEvmTransactionConfirmed(tester);

      final txHash = await readEvmTransactionHash(tester);
      expect(txHash, startsWith('0x'));
      expect(txHash, hasLength(66));

      await openEvmExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        EvmTransactionStatusUtils.explorerUrl(
          chainId: currentWallet.chainId,
          txHash: txHash,
          chainType: currentWallet.chainType,
          networkType: currentWallet.networkType,
        ),
      );

      final broadcastActivity = await waitForWalletActivityByTxHash(
        tester,
        walletId: currentWallet.id,
        txHash: txHash,
        status: AssetActivityStatus.confirmed,
      );
      expect(broadcastActivity.status.name, 'confirmed');

      await openEvmTransactionLookupFromStatus(tester);
      await expectEvmTransactionLookupPage(tester);
      await expectEvmLookupHashFieldValue(tester, txHash: txHash);

      await openEvmExplorerFromLookupPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        EvmTransactionStatusUtils.explorerUrl(
          chainId: currentWallet.chainId,
          txHash: txHash,
          chainType: currentWallet.chainType,
          networkType: currentWallet.networkType,
        ),
      );

      await lookupEvmTransactionByHash(tester, txHash: txHash);
      await expectEvmTransactionStatusPage(tester);
      await waitForEvmTransactionConfirmed(tester);
      expect(await readEvmTransactionHash(tester), txHash);

      await returnToWalletHomeFromStatusPage(tester);
      await openAssetDetailFromWalletHome(
        tester,
        chainId: currentWallet.chainId,
        symbol: 'ETH',
      );
      await expectAssetDetailPage(tester, symbol: 'ETH');
      await openRecentAssetDetailActivityByTxHash(tester, txHash: txHash);

      await expectEvmTransactionStatusPage(tester);
      expect(await readEvmTransactionHash(tester), txHash);

      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 600));
      await expectAssetDetailPage(tester, symbol: 'ETH');

      await openAllActivityFromAssetDetail(tester);
      await expectAssetActivityPage(tester, symbol: 'ETH');
      await openAssetActivityByTxHash(tester, txHash: txHash);

      await expectEvmTransactionStatusPage(tester);
      expect(await readEvmTransactionHash(tester), txHash);
    },
    skip: walletConfig == null || !walletConfig.hasFundedOptimismTestnetWallet,
  );
}
