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
    'broadcasts a real polygon amoy transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedPolygonTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddPolygonTestnetWallet(
        tester,
        walletName: 'Polygon Funded',
        mnemonic: config.fundedPolygonTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kPolygonTestnetChainId);
      expect(
        currentWallet.defaultAddress?.address.toLowerCase(),
        config.fundedPolygonTestnetAddress.toLowerCase(),
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'POL',
      );

      await openTransferFromWalletHome(tester);
      await expectEvmTransferPage(tester);

      await fillEvmTransferForm(
        tester,
        address: config.polygonTestnetTransferRecipientAddress,
        amount: config.polygonTestnetTransferAmount,
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
        symbol: 'POL',
      );
      await expectAssetDetailPage(tester, symbol: 'POL');
      await openRecentAssetDetailActivityByTxHash(tester, txHash: txHash);

      await expectEvmTransactionStatusPage(tester);
      expect(await readEvmTransactionHash(tester), txHash);

      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 600));
      await expectAssetDetailPage(tester, symbol: 'POL');

      await openAllActivityFromAssetDetail(tester);
      await expectAssetActivityPage(tester, symbol: 'POL');
      await openAssetActivityByTxHash(tester, txHash: txHash);

      await expectEvmTransactionStatusPage(tester);
      expect(await readEvmTransactionHash(tester), txHash);
    },
    skip: walletConfig == null || !walletConfig.hasFundedPolygonTestnetWallet,
  );
}
