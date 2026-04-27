import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

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
    'rejects tron transfer on configured network when password is wrong',
    (tester) async {
      final config = walletConfig;
      expect(config, isNotNull);
      expect(config!.hasFundedTrxWalletForTransferNetwork, isTrue);
      final trxNetwork = config.trxTransferNetwork;

      await launchTestApp();

      await importWalletAndAddTrxWalletForNetwork(
        tester,
        network: trxNetwork,
        walletName: 'TRON Wrong',
        mnemonic: config.fundedTrxMnemonic,
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
      await unlockPasswordPrompt(tester, password: 'WrongPass1!');
      await waitForToastMessage(tester, toastMessages);
      expect(
        toastMessages.any((message) => message.contains('密码错误，请重试')),
        isTrue,
      );
      await expectTrxTransferPage(tester);
      expect(find.text('TRX 转账状态'), findsNothing);
    },
    skip:
        walletConfig == null ||
        !walletConfig.hasFundedTrxWalletForTransferNetwork,
  );
}
