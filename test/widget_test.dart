import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

class _EmptyWalletProvider extends WalletProvider {
  @override
  bool get isLoading => false;

  @override
  WalletInfo? get currentWallet => null;
}

void main() {
  testWidgets('MainPage smoke build with no wallet', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<WalletProvider>.value(
        value: _EmptyWalletProvider(),
        child: const MaterialApp(home: MainPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bottom_nav_home')), findsOneWidget);
    expect(find.byKey(const Key('bottom_nav_transaction')), findsOneWidget);
    expect(find.byKey(const Key('bottom_nav_profile')), findsOneWidget);
  });
}
