import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows unlock gate when app lock is triggered', (tester) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'AUTO LOCK');
    await expectWalletHome(tester, walletName: 'AUTO LOCK');

    final context = tester.element(find.byType(MainPage));
    final securityController = Provider.of<SecuritySettingsController>(
      context,
      listen: false,
    );
    await securityController.setAutoLockDuration(AppAutoLockDuration.minute1);

    final appLockController = Provider.of<AppLockController>(
      context,
      listen: false,
    );
    appLockController.lockNow();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app_lock_title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('app_lock_unlock_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app_lock_title')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('app_lock_password_field')),
      'wrong',
    );
    await tester.tap(find.byKey(const Key('app_lock_unlock_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app_lock_title')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('app_lock_password_field')),
      'Passw0rd!',
    );
    await tester.tap(find.byKey(const Key('app_lock_unlock_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app_lock_title')), findsNothing);
  });
}
