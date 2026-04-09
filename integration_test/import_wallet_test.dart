import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('boots app and imports a real mnemonic wallet', (tester) async {
    await launchTestApp();

    await importWalletFromHome(tester, walletName: 'Import BTC');
    await expectPostImportPromptVisible(tester);
    await chooseViewWalletFromPostImportPrompt(tester);

    await expectWalletHome(tester, walletName: 'Import BTC');
  });
}
