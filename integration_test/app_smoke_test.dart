import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('boots app and completes a real create-wallet smoke flow', (
    tester,
  ) async {
    await launchTestApp();

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('home_create_wallet_button')),
    );
    expect(find.text('Zero Wallet'), findsOneWidget);
    await createWalletFromHome(tester, walletName: 'E2E Wallet');

    await expectWalletHome(tester, walletName: 'E2E Wallet');
    await unfocusAndPump(tester, settle: const Duration(seconds: 1));

    await tapAndPump(tester, find.byKey(const Key('bottom_nav_transaction')));
    await expectTextVisible(tester, '交易功能开发中');

    await tapAndPump(tester, find.byKey(const Key('bottom_nav_profile')));
    await expectTextVisible(tester, '个人页面');

    await tapAndPump(tester, find.byKey(const Key('bottom_nav_home')));
    await expectTextVisible(tester, 'E2E Wallet');
  });
}
