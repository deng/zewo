import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();
  final toastMessages = <String>[];

  setUp(() async {
    await captureToastMessages(toastMessages);
  });

  tearDown(() async {
    await stopCapturingToastMessages();
  });

  testWidgets(
    'cancels tron mainnet transfer at password prompt and stays on transfer page',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedTrxMainnetWallet, isTrue);
      final trxNetwork = config.trxTransferNetwork;

      await launchTestApp();

      await importWalletAndAddTrxWalletForNetwork(
        tester,
        network: trxNetwork,
        walletName: 'TRON Cancel',
        mnemonic: config.fundedTrxMainnetMnemonic,
      );

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(
        currentWallet!.chainId,
        trxChainIdForIntegrationNetwork(trxNetwork),
      );

      await waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
        tester,
        symbol: 'TRX',
      );

      await openTransferFromWalletHome(tester);
      await expectTrxTransferPage(tester);

      toastMessages.clear();
      await fillTrxTransferForm(
        tester,
        address: config.trxTransferRecipientAddress,
        amount: config.trxTransferAmount,
      );
      await submitTrxTransfer(tester);

      await expectPasswordVerificationDialogVisible(tester);
      await cancelPasswordVerificationDialog(tester);
      await expectTrxTransferPage(tester);
      expect(find.text('TRX 转账状态'), findsNothing);
    },
    skip: walletConfig == null || !walletConfig.hasFundedTrxMainnetWallet,
  );
}
