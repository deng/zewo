import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows visible error for mnemonic with invalid checksum', (
    tester,
  ) async {
    await launchTestApp();

    await openImportWalletFromHome(tester);

    await fillImportWalletForm(
      tester,
      walletName: 'Invalid Mn',
      mnemonic: kInvalidChecksumMnemonic,
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('import_wallet_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await expectImportWalletError(tester, '请输入有效的助记词');
    expectPostImportPromptHidden();
  });
}
