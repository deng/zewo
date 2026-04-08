import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows form error when create wallet password is too short', (
    tester,
  ) async {
    await launchTestApp();

    await openCreateWalletFromHome(tester);

    await fillCreateWalletForm(
      tester,
      walletName: 'Wallet One',
      password: 'Pass1!',
      confirmPassword: 'Pass1!',
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('create_wallet_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await expectValidationError(tester, '密码长度至少8位');
    await expectCreateWalletPageVisible(tester);
    expect(find.text('钱包'), findsNothing);
  });
}
