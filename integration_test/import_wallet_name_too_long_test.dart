import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows form error when imported wallet name exceeds 24 chars', (
    tester,
  ) async {
    await launchTestApp();

    await openImportWalletFromHome(tester);

    await fillImportWalletForm(
      tester,
      walletName: 'Wallet Name Exceeds Limit 01',
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('import_wallet_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await expectValidationError(tester, '钱包名称不能超过24个字符');
    expectPostImportPromptHidden();
  });
}
