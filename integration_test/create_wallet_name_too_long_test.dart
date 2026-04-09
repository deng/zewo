import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows form error when created wallet name exceeds 12 chars', (
    tester,
  ) async {
    await launchTestApp();

    await openCreateWalletFromHome(tester);

    await fillCreateWalletForm(tester, walletName: 'Wallet Name 01');

    await tapAndPump(
      tester,
      find.byKey(const Key('create_wallet_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await expectValidationError(tester, '钱包名称不能超过12个字符');
    await expectCreateWalletPageVisible(tester);
    expect(find.text('钱包'), findsNothing);
  });
}
