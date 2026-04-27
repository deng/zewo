import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';
import 'test_wallet_config.dart';

void main() {
  configureIntegrationTest();

  final walletConfig = loadIntegrationTestWalletConfig();
  final trxNetwork = walletConfig?.trxTransferNetwork ?? kTrxNetworkNile;
  final toastMessages = <String>[];

  group('TRON transfer preflight ($trxNetwork)', () {
    setUp(() async {
      await captureToastMessages(toastMessages);
    });

    tearDown(() async {
      await stopCapturingToastMessages();
    });

    testWidgets(
      'shows validation error for invalid tron address on configured network',
      (tester) async {
        await launchTestApp();

        await createWalletAndAddTrxWalletForNetwork(
          tester,
          network: trxNetwork,
          walletName: 'TRON ${trxNetwork.toUpperCase()}',
        );

        final currentWallet = WalletProvider.getInstance()?.currentWallet;
        expect(currentWallet, isNotNull);
        expect(
          currentWallet!.chainId,
          trxChainIdForIntegrationNetwork(trxNetwork),
        );

        await openTransferFromWalletHome(tester);
        await expectTrxTransferPage(tester);

        await fillTrxTransferForm(
          tester,
          address: 'invalid-address',
          amount: '1',
        );
        await submitTrxTransfer(tester);

        expectLatestToastMessage(toastMessages, '请输入有效的 TRON 地址');
        await expectTrxTransferPage(tester);
      },
    );
  });
}
