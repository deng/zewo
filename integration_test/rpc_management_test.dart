import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('RPC management: multi-endpoint add/delete for BTC and EVM', (
    tester,
  ) async {
    // ====== Part 1: BTC wallet multi-endpoint ======
    await launchTestApp();
    await createWalletFromHome(tester, walletName: 'BTC-Wallet');

    await expectWalletHome(tester, walletName: 'BTC-Wallet');
    await openWalletDetailFromHome(tester);
    await expectTextVisible(tester, '钱包详情');

    // Open Chain Info for BTC
    await tapAndPump(
      tester,
      find.byKey(const Key('wallet_detail_chain_info_tile')),
    );
    await pumpUntilVisible(tester, find.text('链信息'));

    // Should show RPC Endpoints section
    await expectTextVisible(tester, 'RPC 端点');

    // Should show empty state
    await expectTextVisible(tester, '尚未配置自定义 RPC 端点');

    // Add first RPC endpoint
    final addField = find.byType(TextField);
    expect(addField, findsOneWidget);
    await tester.enterText(
      addField,
      'https://mempool.space/api',
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Find and tap Add button
    final addButton = find.widgetWithText(FilledButton, '添加');
    expect(addButton, findsOneWidget);
    await tapAndPump(
      tester,
      addButton,
      settle: const Duration(seconds: 1),
    );

    // The endpoint should appear in the list
    await pumpUntilVisible(tester, find.text('https://mempool.space/api'));

    // Add a second endpoint
    final addField2 = find.byType(TextField);
    await tester.enterText(
      addField2,
      'https://btc.nownodes.io',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tapAndPump(
      tester,
      find.widgetWithText(FilledButton, '添加'),
      settle: const Duration(seconds: 1),
    );
    await pumpUntilVisible(tester, find.text('https://btc.nownodes.io'));

    // Duplicate URL should show warning
    final addField3 = find.byType(TextField);
    await tester.enterText(
      addField3,
      'https://mempool.space/api',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tapAndPump(
      tester,
      find.widgetWithText(FilledButton, '添加'),
      settle: const Duration(seconds: 1),
    );
    // Should still show duplicate warning - endpoint list unchanged
    expect(find.text('URL 已存在'), findsOneWidget);
    // Verify both endpoints still present
    expect(find.text('https://mempool.space/api'), findsOneWidget);
    expect(find.text('https://btc.nownodes.io'), findsOneWidget);

    // Delete first endpoint
    final deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons, findsNWidgets(2));
    await tapAndPump(
      tester,
      deleteButtons.first,
      settle: const Duration(milliseconds: 500),
    );

    // Confirm delete dialog
    await pumpUntilVisible(tester, find.text('删除此 RPC 端点？'));
    await tapAndPump(
      tester,
      find.widgetWithText(TextButton, '删除'),
      settle: const Duration(seconds: 1),
    );

    // Should now see only one endpoint
    expect(find.text('https://btc.nownodes.io'), findsOneWidget);
    expect(find.text('https://mempool.space/api'), findsNothing);

    // Go back to home
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // ====== Part 2: ETH Sepolia multi-endpoint ======
    await openWalletDetailFromHome(tester);
    await expectTextVisible(tester, '钱包详情');
    await openHdManageFromWalletDetail(tester);
    await expectTextVisible(tester, '添加钱包');
    await openAddWalletFromHdManage(tester);
    await expectTextVisible(tester, '添加钱包');
    await addHdWalletByChainId(
      tester,
      chainId: '11155111',
      password: 'Passw0rd!',
    );
    await pumpUntilWalletHomeReady(tester);

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.chainId, '11155111');

    // Navigate to wallet detail
    await openWalletDetailFromHome(tester);
    await expectTextVisible(tester, '钱包详情');

    // Open Chain Info
    await tapAndPump(
      tester,
      find.byKey(const Key('wallet_detail_chain_info_tile')),
    );
    await pumpUntilVisible(tester, find.text('链信息'));

    // Should show chain ID and RPC section
    await expectTextVisible(tester, '11155111');
    await expectTextVisible(tester, 'RPC 端点');

    // Add an RPC endpoint
    final ethAddField = find.byType(TextField);
    await tester.enterText(
      ethAddField,
      'https://eth-sepolia.g.alchemy.com/v2/custom-key',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tapAndPump(
      tester,
      find.widgetWithText(FilledButton, '添加'),
      settle: const Duration(seconds: 2),
    );

    // Endpoint should appear
    await pumpUntilVisible(
      tester,
      find.text('https://eth-sepolia.g.alchemy.com/v2/custom-key'),
    );

    // Delete it
    final ethDeleteButtons = find.byIcon(Icons.delete_outline);
    expect(ethDeleteButtons, findsOneWidget);
    await tapAndPump(
      tester,
      ethDeleteButtons.first,
      settle: const Duration(milliseconds: 500),
    );
    await pumpUntilVisible(tester, find.text('删除此 RPC 端点？'));
    await tapAndPump(
      tester,
      find.widgetWithText(TextButton, '删除'),
      settle: const Duration(seconds: 1),
    );

    // Should be back to empty state
    await expectTextVisible(tester, '尚未配置自定义 RPC 端点');
  });
}
