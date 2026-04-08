import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows form error when import wallet passwords do not match', (
    tester,
  ) async {
    await launchTestApp();

    await openImportWalletFromHome(tester);

    await fillImportWalletForm(
      tester,
      walletName: 'Import BTC',
      confirmPassword: 'Passw0rd?',
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('import_wallet_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await expectValidationError(tester, '两次输入的密码不一致');
    expectPostImportPromptHidden();
  });
}
