import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows form error when imported mnemonic word count is invalid', (
    tester,
  ) async {
    await launchTestApp();

    await openImportWalletFromHome(tester);

    await fillImportWalletForm(
      tester,
      walletName: 'Import BTC',
      mnemonic:
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon',
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('import_wallet_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await expectValidationError(tester, '助记词数量必须为 12 / 15 / 18 / 21 / 24 个');
    expectPostImportPromptHidden();
  });
}
