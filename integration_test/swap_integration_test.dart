import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/src/core/wallet_provider.dart';
import 'package:zero_wallet/src/models/asset_models.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('swap history page shows empty state when no swaps exist', (
    tester,
  ) async {
    await launchTestApp();

    // Create a wallet
    await importWalletThenViewWallet(tester, walletName: 'Swap Test Wallet');
    await pumpUntilWalletHomeReady(tester, walletName: 'Swap Test Wallet');

    // Navigate to swap tab
    await tapAndPump(
      tester,
      find.byKey(const Key('bottom_nav_swap')),
      settle: const Duration(seconds: 1),
    );

    // Wait for swap page to render
    await pumpUntilVisible(tester, find.text('交易'));
    expect(find.text('交易'), findsOneWidget);

    // Open swap history page (history icon button in AppBar)
    await tapAndPump(
      tester,
      find.byTooltip('历史记录'),
      settle: const Duration(seconds: 1),
    );

    // Should see swap history page title
    await pumpUntilVisible(tester, find.text('兑换历史'));
    expect(find.text('兑换历史'), findsOneWidget);

    // Should see empty state message
    await pumpUntilVisible(tester, find.text('暂无兑换记录'));
    expect(find.text('暂无兑换记录'), findsOneWidget);
  });

  testWidgets('swap history page shows recorded swap activities', (
    tester,
  ) async {
    await launchTestApp();

    // Create a wallet
    await importWalletThenViewWallet(tester, walletName: 'History Test');
    await pumpUntilWalletHomeReady(tester, walletName: 'History Test');

    // Record a swap activity directly via WalletProvider
    final provider = WalletProvider.getInstance()!;
    final wallet = provider.currentWallet!;

    provider.recordAssetActivity(AssetActivityRecord(
      walletId: wallet.id,
      chainId: wallet.chainId,
      symbol: 'ETH',
      contractAddress: null,
      isNative: true,
      type: AssetActivityType.swap,
      status: AssetActivityStatus.confirmed,
      txHash: '0xmock_swap_tx_hash_12345',
      fromAddress: wallet.defaultAddress?.address ?? '',
      toAddress: wallet.defaultAddress?.address ?? '',
      amountLabel: '0.1 ETH',
      feeLabel: '0.002 ETH',
      toSymbol: 'USDC',
      toAmountLabel: '250.00',
      createdAt: DateTime.now(),
    ));

    // Also record a send activity (should not appear in swap history)
    provider.recordAssetActivity(AssetActivityRecord(
      walletId: wallet.id,
      chainId: wallet.chainId,
      symbol: 'ETH',
      contractAddress: null,
      isNative: true,
      type: AssetActivityType.send,
      status: AssetActivityStatus.confirmed,
      txHash: '0xmock_send_tx_hash',
      fromAddress: wallet.defaultAddress?.address ?? '',
      toAddress: '0xrecipient',
      amountLabel: '0.5 ETH',
      feeLabel: '0.002 ETH',
      createdAt: DateTime.now(),
    ));

    await tester.pump(const Duration(milliseconds: 500));

    // Navigate to swap tab
    await tapAndPump(
      tester,
      find.byKey(const Key('bottom_nav_swap')),
      settle: const Duration(seconds: 1),
    );
    await pumpUntilVisible(tester, find.text('交易'));

    // Open swap history
    await tapAndPump(
      tester,
      find.byTooltip('历史记录'),
      settle: const Duration(seconds: 1),
    );
    await pumpUntilVisible(tester, find.text('兑换历史'));

    // Should show the recorded swap (from amount + arrow + to amount + symbol)
    await pumpUntilVisible(tester, find.textContaining('0.1 ETH'));
    await pumpUntilVisible(tester, find.textContaining('USDC'));

    // Should NOT show the send activity
    expect(find.textContaining('0.5 ETH'), findsNothing);

    // Should show the wallet name
    await expectTextVisible(tester, 'History Test');
  });

  testWidgets('swap page renders basic UI elements', (tester) async {
    await launchTestApp();

    // Create a wallet
    await importWalletThenViewWallet(tester, walletName: 'UI Test');
    await pumpUntilWalletHomeReady(tester, walletName: 'UI Test');

    // Navigate to swap tab (index 1)
    await tapAndPump(
      tester,
      find.byKey(const Key('bottom_nav_swap')),
      settle: const Duration(seconds: 1),
    );

    // Verify page title
    await pumpUntilVisible(tester, find.text('交易'));
    expect(find.text('交易'), findsOneWidget);

    // Verify chain selector present
    await expectTextVisible(tester, '选择链');

    // Verify from/to labels
    await expectTextVisible(tester, '你支付');
    await expectTextVisible(tester, '你收到');

    // Verify token selection buttons present
    await expectTextVisible(tester, '选择代币');
    expect(find.byIcon(Icons.swap_vert), findsOneWidget);

    // Verify settings icon (tune icon) in AppBar
    expect(
      find.byTooltip('DEX 设置'),
      findsOneWidget,
    );

    // Verify history icon in AppBar
    expect(
      find.byTooltip('历史记录'),
      findsOneWidget,
    );
  });

  testWidgets('swap page shows dex settings page', (tester) async {
    await launchTestApp();

    await importWalletThenViewWallet(tester, walletName: 'Settings Test');
    await pumpUntilWalletHomeReady(tester, walletName: 'Settings Test');

    // Navigate to swap tab
    await tapAndPump(
      tester,
      find.byKey(const Key('bottom_nav_swap')),
      settle: const Duration(seconds: 1),
    );
    await pumpUntilVisible(tester, find.text('交易'));

    // Tap settings icon
    await tapAndPump(
      tester,
      find.byTooltip('DEX 设置'),
      settle: const Duration(seconds: 1),
    );

    // Verify settings page title
    await pumpUntilVisible(tester, find.text('DEX 设置'));
    expect(find.text('DEX 设置'), findsOneWidget);

    // Verify default slippage setting field
    await pumpUntilVisible(tester, find.text('默认滑点'));
    expect(find.text('默认滑点'), findsOneWidget);
  });

  testWidgets('swap activity appears in asset activity', (tester) async {
    await launchTestApp();

    await importWalletThenViewWallet(tester, walletName: 'Activity Test');
    await pumpUntilWalletHomeReady(tester, walletName: 'Activity Test');

    // Get wallet info
    final provider = WalletProvider.getInstance()!;
    final wallet = provider.currentWallet!;

    // Record a swap activity
    const swapTxHash = '0xmock_swap_activity_hash';
    provider.recordAssetActivity(AssetActivityRecord(
      walletId: wallet.id,
      chainId: wallet.chainId,
      symbol: 'ETH',
      contractAddress: null,
      isNative: true,
      type: AssetActivityType.swap,
      status: AssetActivityStatus.confirmed,
      txHash: swapTxHash,
      fromAddress: wallet.defaultAddress?.address ?? '',
      toAddress: wallet.defaultAddress?.address ?? '',
      amountLabel: '0.1 ETH',
      feeLabel: '',
      toSymbol: 'USDC',
      toAmountLabel: '250.00',
      createdAt: DateTime.now(),
    ));

    await tester.pump(const Duration(seconds: 1));

    // Verify swap activity is retrievable via WalletProvider
    final activities = provider.getWalletAssetActivities(wallet.id);
    final swapActivities =
        activities.where((a) => a.type == AssetActivityType.swap).toList();
    expect(swapActivities, hasLength(1));
    expect(swapActivities.first.txHash, swapTxHash);
    expect(swapActivities.first.amountLabel, '0.1 ETH');
    expect(swapActivities.first.toSymbol, 'USDC');
    expect(swapActivities.first.toAmountLabel, '250.00');

    // Open asset activity page and verify swap activity shows with swap icon
    await openAssetDetailFromWalletHome(
      tester,
      chainId: wallet.chainId,
      symbol: 'ETH',
    );
    await expectAssetDetailPage(tester, symbol: 'ETH');

    await openAllActivityFromAssetDetail(tester);
    await expectAssetActivityPage(tester, symbol: 'ETH');

    // Find the swap activity
    await pumpUntilVisible(
      tester,
      find.byKey(Key('asset_activity_item_$swapTxHash')),
    );
    expect(
      find.byKey(Key('asset_activity_item_$swapTxHash')),
      findsOneWidget,
    );

    // Should show swap icon
    final activityCard = find.byKey(Key('asset_activity_item_$swapTxHash'));
    expect(
      find.descendant(of: activityCard, matching: find.byIcon(Icons.swap_horiz)),
      findsOneWidget,
    );

    // Should display the swap direction (toAmount → toSymbol)
    await expectTextVisible(tester, '250.00');
  });
}
