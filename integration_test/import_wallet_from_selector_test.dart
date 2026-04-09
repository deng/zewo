import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('imports a second mnemonic wallet from wallet selector', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'Wallet One');

    await pumpUntilWalletHomeReady(tester, walletName: 'Wallet One');

    await importWalletFromSelector(
      tester,
      walletName: 'Imported 2',
      mnemonic: kSecondValidImportMnemonic,
    );

    await expectPostImportPromptVisible(tester);
    await chooseViewWalletFromPostImportPrompt(tester);

    await expectWalletHome(tester, walletName: 'Imported 2');
  });
}
