import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets(
    'shows required error when create wallet confirm password is empty',
    (tester) async {
      await launchTestApp();

      await openCreateWalletFromHome(tester);

      await fillCreateWalletForm(
        tester,
        walletName: 'Wallet One',
        confirmPassword: null,
      );

      await tapAndPump(
        tester,
        find.byKey(const Key('create_wallet_submit_button')),
        settle: const Duration(seconds: 1),
      );

      await expectValidationError(tester, '请确认密码');
      await expectCreateWalletPageVisible(tester);
    },
  );
}
