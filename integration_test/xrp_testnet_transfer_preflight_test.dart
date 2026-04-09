import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

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

  testWidgets('shows validation error for invalid xrp testnet address', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddXrpTestnetWallet(tester, walletName: 'XRP Testnet');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, 'xrp_testnet');

    await openTransferFromWalletHome(tester);
    await expectXrpTransferPage(tester);

    await fillXrpTransferForm(tester, address: 'bad-address', amount: '1');
    await submitXrpTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 XRP 地址');
    await expectXrpTransferPage(tester);
  });
}
