import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('creates wallet then opens receive page and sets amount', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'Receive One');
    await expectWalletHome(tester, walletName: 'Receive One');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    final currentAddress = currentWallet?.defaultAddress?.address;

    expect(currentWallet, isNotNull);
    expect(currentAddress, isNotNull);
    expect(currentAddress, isNotEmpty);

    await openReceiveFromWalletHome(tester);
    await expectWalletReceivePage(tester, address: currentAddress);

    await setReceiveAmount(tester, '12.34');
    await expectTextVisible(tester, '12.34 BTC');
  });
}
