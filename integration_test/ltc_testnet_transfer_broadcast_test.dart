import 'package:bipx/bipx.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';
import 'package:wallet/src/coins/ltc/utils/ltc_transaction_status_utils.dart';

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
    'broadcasts a real ltc testnet transfer with funded wallet',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedLtcTestnetWallet, isTrue);

      await launchTestApp();

      await importWalletAndAddLtcTestnetWallet(
        tester,
        walletName: 'LTC Funded',
        mnemonic: config.fundedLtcTestnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, kLtcTestnetChainId);
      expect(
        currentWallet.defaultAddress?.address,
        config.fundedLtcTestnetAddress,
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZeroForChain(
        tester,
        chainId: kLtcTestnetChainId,
        timeout: const Duration(minutes: 2),
      );

      await openTransferFromWalletHome(tester);
      await expectLtcTransferPage(tester);

      await fillLtcTransferForm(
        tester,
        address: config.ltcTestnetTransferRecipientAddress,
        amount: config.ltcTestnetTransferAmount,
      );
      await submitLtcTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await unlockPasswordPrompt(tester);

      await expectLtcTransactionStatusPage(
        tester,
        timeout: const Duration(minutes: 2),
      );
      await waitForLtcTransactionBroadcastedOrConfirmed(tester);

      final txHash = await readLtcTransactionHash(tester);
      expect(RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(txHash), isTrue);

      await openLtcExplorerFromStatusPage(tester);
      expectLatestExternalLaunchUrl(
        launchedUrls,
        LtcTransactionStatusUtils.explorerUrl(
          txid: txHash,
          networkType: NetworkType.testnet,
        ),
      );

      await returnToWalletHomeFromStatusPage(tester);
      await pumpUntilVisible(
        tester,
        find.byKey(const Key('wallet_home_selector_button')),
      );
    },
    skip: walletConfig == null || !walletConfig.hasFundedLtcTestnetWallet,
  );
}
