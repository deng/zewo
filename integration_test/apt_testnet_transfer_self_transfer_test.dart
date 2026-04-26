import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  final toastMessages = <String>[];

  setUp(() async {
    await captureToastMessages(toastMessages);
  });

  tearDown(() async {
    await stopCapturingToastMessages();
  });

  testWidgets('shows validation when apt testnet transfer targets self', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddAptTestnetWallet(tester, walletName: 'APT Self');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    final selfAddress = currentWallet!.defaultAddress;
    expect(selfAddress, isNotNull);

    await openTransferFromWalletHome(tester);
    await expectAptTransferPage(tester);

    await fillAptTransferForm(
      tester,
      address: selfAddress!.address,
      amount: '1',
    );
    await submitAptTransfer(tester);

    expectLatestToastMessage(toastMessages, '不能向当前 Aptos 地址本身转账');
    await expectAptTransferPage(tester);
  });
}
