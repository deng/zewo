import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

Future<void> main() async {
  await bootstrapZeroWalletApp();
}

Future<void> bootstrapZeroWalletApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 AppLifecycleManager
  await AppLifecycleManager.instance.initialize();

  runApp(const ZeroWalletApp());
}

class ZeroWalletApp extends StatefulWidget {
  const ZeroWalletApp({super.key});

  @override
  State<ZeroWalletApp> createState() => _ZeroWalletAppState();
}

class _ZeroWalletAppState extends State<ZeroWalletApp> {
  late final ThemeData _lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  late final ThemeData _darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // 在应用关闭时释放 AppLifecycleManager 的资源
    AppLifecycleManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 来自 wallet 库的 WalletProvider
        ChangeNotifierProvider(
          create: (context) {
            final provider = WalletProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final controller = UsageSettingsController();
            controller.initialize();
            return controller;
          },
        ),
      ],
      child:
          Selector<
            UsageSettingsController,
            ({ThemeMode themeMode, bool developerMode})
          >(
            selector: (_, controller) => (
              themeMode: controller.themeMode,
              developerMode: controller.developerMode,
            ),
            builder: (context, usageSettings, child) {
              return MaterialApp(
                title: 'Zero Wallet',
                onGenerateRoute: WalletRoutes.onGenerateRoute,
                theme: _lightTheme,
                darkTheme: _darkTheme,
                themeMode: usageSettings.themeMode,
                builder: (context, child) {
                  if (child == null || !usageSettings.developerMode) {
                    return child ?? const SizedBox.shrink();
                  }
                  return Banner(
                    message: 'DEV',
                    location: BannerLocation.topEnd,
                    child: child,
                  );
                },
                home: const MainPage(),
              );
            },
          ),
    );
  }
}
