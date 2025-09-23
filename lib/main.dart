import 'package:flutter/material.dart';
import 'package:wallet/wallet.dart';

void main() {
  runApp(const ZeroWalletApp());
}

class ZeroWalletApp extends StatelessWidget {
  const ZeroWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark, // 强制使用深色主题
      home: const MainPage(), // 使用统一的主页面
    );
  }
}
