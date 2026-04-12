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
    'broadcasts a real tron ${walletConfig?.trxTransferNetwork ?? 'configured'} transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedTrxWalletForTransferNetwork, isTrue);
      final trxNetwork = config.trxTransferNetwork;

      await launchTestApp();

      await importWalletAndAddTrxWalletForNetwork(
        tester,
        network: trxNetwork,
        walletName: 'TRON Funded',
        mnemonic: config.fundedTrxMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(
        currentWallet!.chainId,
        trxChainIdForIntegrationNetwork(trxNetwork),
      );
      expect(currentWallet.defaultAddress?.address, config.fundedTrxAddress);

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'TRX',
      );

      await openTransferFromWalletHome(tester);
      await expectTrxTransferPage(tester);

      await fillTrxTransferForm(
        tester,
        address: config.trxTransferRecipientAddress,
        amount: config.trxTransferAmount,
      );
      await submitTrxTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectTrxTransactionStatusPage(tester);
      await waitForTrxTransactionConfirmed(tester);

      final txHash = await readTrxTransactionHash(tester);
      expect(RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(txHash), isTrue);

      await openTrxExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        '${trxExplorerTxBaseUrlForIntegrationNetwork(trxNetwork)}$txHash',
      );

      await returnToWalletHomeFromStatusPage(tester);
      await pumpUntilVisible(
        tester,
        find.byKey(const Key('wallet_home_selector_button')),
      );
    },
    skip:
        walletConfig == null ||
        !walletConfig.hasFundedTrxWalletForTransferNetwork,
  );
}
