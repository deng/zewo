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
    'broadcasts a real xrp testnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedXrpTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddXrpTestnetWallet(
        tester,
        walletName: 'XRP Funded',
        mnemonic: config.fundedXrpTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'xrp_testnet');
      expect(
        currentWallet.defaultAddress?.address,
        config.fundedXrpTestnetAddress,
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'XRP',
      );

      await openTransferFromWalletHome(tester);
      await expectXrpTransferPage(tester);

      await fillXrpTransferForm(
        tester,
        address: config.xrpTestnetTransferRecipientAddress,
        amount: config.xrpTestnetTransferAmount,
        destinationTag: config.xrpTestnetTransferDestinationTagOrNull,
      );
      await submitXrpTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectXrpTransactionStatusPage(tester);
      await waitForXrpTransactionConfirmed(tester);

      final txHash = await readXrpTransactionHash(tester);
      expect(txHash, hasLength(64));

      await openXrpExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        XrpTransactionStatusUtils.explorerUrl(
          txHash: txHash,
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

      await openXrpTransactionLookupFromStatus(tester);
      await expectXrpTransactionLookupPage(tester);
      await expectXrpLookupHashFieldValue(tester, txHash: txHash);

      await openXrpExplorerFromLookupPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        XrpTransactionStatusUtils.explorerUrl(
          txHash: txHash,
          networkType: currentWallet.networkType,
        ),
      );

      await lookupXrpTransactionByHash(tester, txHash: txHash);
      await expectXrpTransactionStatusPage(tester);
      await waitForXrpTransactionConfirmed(tester);
      expect(await readXrpTransactionHash(tester), txHash);

      await returnToWalletHomeFromStatusPage(tester);
      await openAssetDetailFromWalletHome(
        tester,
        chainId: currentWallet.chainId,
        symbol: 'XRP',
      );
      await expectAssetDetailPage(tester, symbol: 'XRP');
      await openRecentAssetDetailActivityByTxHash(tester, txHash: txHash);

      await expectXrpTransactionStatusPage(tester);
      expect(await readXrpTransactionHash(tester), txHash);

      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 600));
      await expectAssetDetailPage(tester, symbol: 'XRP');

      await openAllActivityFromAssetDetail(tester);
      await expectAssetActivityPage(tester, symbol: 'XRP');
      await openAssetActivityByTxHash(tester, txHash: txHash);

      await expectXrpTransactionStatusPage(tester);
      expect(await readXrpTransactionHash(tester), txHash);
    },
    skip: walletConfig == null || !walletConfig.hasFundedXrpTestnetWallet,
  );
}
