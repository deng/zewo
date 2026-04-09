import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('imports mnemonic then adds an Ethereum HD wallet', (
    tester,
  ) async {
    await launchTestApp();

    await importWalletThenAddNetworks(tester, walletName: 'Import BTC');
    await expectTextVisible(tester, '添加钱包');

    await tapAndPump(tester, find.byKey(const Key('hd_wallet_add_chain_1')));
    await expectTextVisible(tester, 'Ethereum 钱包列表');

    await tapAndPump(
      tester,
      find.byKey(const Key('hd_wallet_list_add_subwallet_1')),
      settle: const Duration(seconds: 1),
    );

    await expectWalletHome(tester, walletName: 'ETH mainnet 钱包 1');
  });
}
