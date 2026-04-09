import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('creates a second wallet from wallet selector and returns home', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'Wallet One');

    await pumpUntilWalletHomeReady(tester, walletName: 'Wallet One');

    await createWalletFromSelector(tester, walletName: 'Wallet Two');

    await expectWalletHome(tester, walletName: 'Wallet Two');
  });
}
