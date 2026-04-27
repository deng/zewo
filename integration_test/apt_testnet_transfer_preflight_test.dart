import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  final toastMessages = <String>[];

  setUp(() async {
    await captureToastMessages(toastMessages);
  });

  tearDown(() async {
    await stopCapturingToastMessages();
  });

  testWidgets(
    'adds apt testnet wallet and validates transfer page on testnet',
    (tester) async {
      await launchTestApp();

      await createWalletAndAddAptTestnetWallet(tester, walletName: 'APT Test');

      final currentWallet = WalletProvider.getInstance()?.currentWallet;
      expect(currentWallet, isNotNull);
      expect(currentWallet!.chainId, 'apt_testnet');

      await openTransferFromWalletHome(tester);
      await expectAptTransferPage(tester);

      await fillAptTransferForm(
        tester,
        address: 'invalid-address',
        amount: '1',
      );
      await submitAptTransfer(tester);

      expectLatestToastMessage(toastMessages, '请输入有效的 Aptos 地址');
    },
  );
}
