import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows required field errors when import wallet form is empty', (
    tester,
  ) async {
    await launchTestApp();

    await openImportWalletFromHome(tester);

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('import_wallet_submit_button')),
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('import_wallet_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await expectValidationErrors(tester, [
      '请输入钱包名称',
      '请输入助记词',
      '请输入密码',
      '请确认密码',
    ]);
    expectPostImportPromptHidden();
  });
}
