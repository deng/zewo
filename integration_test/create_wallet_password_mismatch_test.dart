import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows form error when create wallet passwords do not match', (
    tester,
  ) async {
    await launchTestApp();

    await openCreateWalletFromHome(tester);

    await fillCreateWalletForm(
      tester,
      walletName: 'Wallet One',
      confirmPassword: 'Passw0rd?',
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('create_wallet_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await expectValidationError(tester, '两次输入的密码不一致');
    await expectCreateWalletPageVisible(tester);
    expect(find.text('钱包'), findsNothing);
  });
}
