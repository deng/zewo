import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('shows visible error when importing the same mnemonic twice', (
    tester,
  ) async {
    await launchTestApp();

    await importWalletThenViewWallet(tester, walletName: 'Import BTC');
    await importWalletFromSelector(tester, walletName: 'Import Again');

    await expectImportWalletError(tester, '助记词已存在，不能重复导入');
    expectPostImportPromptHidden();
  });
}
