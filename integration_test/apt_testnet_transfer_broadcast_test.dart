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
    'broadcasts a real apt testnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedAptTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddAptTestnetWallet(
        tester,
        walletName: 'APT Funded',
        mnemonic: config.fundedAptTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'apt_testnet');
      expect(
        currentWallet.defaultAddress?.address.toLowerCase(),
        config.fundedAptTestnetAddress.toLowerCase(),
      );
      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'APT',
      );

      await openTransferFromWalletHome(tester);
      await expectAptTransferPage(tester);

      await fillAptTransferForm(
        tester,
        address: config.aptTestnetTransferRecipientAddress,
        amount: '0.0001',
      );
      await submitAptTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectAptTransactionStatusPage(tester);
      await waitForAptTransactionConfirmed(tester);

      final txHash = await readAptTransactionHash(tester);
      expect(txHash, startsWith('0x'));
      await openAptExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        AptTransactionStatusUtils.explorerUrl(
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

      await openAptTransactionLookupFromStatus(tester);
      await expectAptTransactionLookupPage(tester);
      await expectAptLookupHashFieldValue(tester, txHash: txHash);
      await openAptExplorerFromLookupPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        AptTransactionStatusUtils.explorerUrl(
          txHash: txHash,
          networkType: currentWallet.networkType,
        ),
      );

      await lookupAptTransactionByHash(tester, txHash: txHash);
      await expectAptTransactionStatusPage(tester);
      await waitForAptTransactionConfirmed(tester);
      expect(await readAptTransactionHash(tester), txHash);

      await returnToWalletHomeFromStatusPage(tester);
      await openAssetDetailFromWalletHome(
        tester,
        chainId: currentWallet.chainId,
        symbol: 'APT',
      );
      await expectAssetDetailPage(tester, symbol: 'APT');
      await openRecentAssetDetailActivityByTxHash(tester, txHash: txHash);

      await expectAptTransactionStatusPage(tester);
      expect(await readAptTransactionHash(tester), txHash);

      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 600));
      await expectAssetDetailPage(tester, symbol: 'APT');

      await openAllActivityFromAssetDetail(tester);
      await expectAssetActivityPage(tester, symbol: 'APT');
      await openAssetActivityByTxHash(tester, txHash: txHash);

      await expectAptTransactionStatusPage(tester);
      expect(await readAptTransactionHash(tester), txHash);
    },
    skip: walletConfig == null || !walletConfig.hasFundedAptTestnetWallet,
  );
}
