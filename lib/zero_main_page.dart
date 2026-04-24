import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/src/core/wallet_provider.dart';
import 'package:wallet/src/ui/pages/home_content_page.dart';
import 'package:wallet/src/ui/pages/profile_page.dart';
import 'package:wallet/src/ui/pages/wallet_home_page.dart';
import 'package:wallet/src/ui/widgets/bottom_navigation_bar.dart';
import 'package:wallet/src/ui/widgets/wallet_scaffold.dart';
import 'package:wallet/wallet.dart' hide WalletProvider;

class ZeroMainPage extends StatefulWidget {
  const ZeroMainPage({super.key});

  @override
  State<ZeroMainPage> createState() => _ZeroMainPageState();
}

class _ZeroMainPageState extends State<ZeroMainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        if (walletProvider.isLoading && walletProvider.currentWallet == null) {
          return WalletScaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }

        if (walletProvider.currentWallet != null) {
          return _buildWalletMainPage();
        }
        return _buildWelcomePage();
      },
    );
  }

  Widget _buildWalletMainPage() {
    final theme = Theme.of(context);
    final pages = <Widget>[
      WalletHomePage(),
      OfflineToolsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[_currentIndex]),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    final theme = Theme.of(context);
    final pages = <Widget>[
      const HomeContent(),
      OfflineToolsPage(),
      const ProfilePage(),
    ];

    return WalletScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[_currentIndex]),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBarWidget(
      currentIndex: _currentIndex,
      onIndexChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}
