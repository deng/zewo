import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('cancels xrp testnet transfer from password prompt', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddXrpTestnetWallet(tester, walletName: 'XRP Cancel');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, 'xrp_testnet');

    await openTransferFromWalletHome(tester);
    await expectXrpTransferPage(tester);

    await fillXrpTransferForm(
      tester,
      address: kValidXrpTransferAddress,
      amount: '1',
    );
    await submitXrpTransfer(tester);

    await expectPasswordVerificationDialogVisible(tester);
    await cancelPasswordVerificationDialog(tester);
    await expectXrpTransferPage(tester);
  });
}
