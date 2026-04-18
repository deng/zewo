import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

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

  testWidgets('shows validation error for invalid polygon amoy address', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletAndAddPolygonTestnetWallet(
      tester,
      walletName: 'Polygon Amoy',
    );

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, kPolygonTestnetChainId);

    await openTransferFromWalletHome(tester);
    await expectEvmTransferPage(tester);

    await fillEvmTransferForm(tester, address: 'invalid-address', amount: '1');
    await submitEvmTransfer(tester);

    expectLatestToastMessage(toastMessages, '请输入有效的 EVM 地址');
    await expectEvmTransferPage(tester);
  });
}
