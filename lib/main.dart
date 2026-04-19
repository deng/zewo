import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  static const _themeSeedColor = Color(0xFF3D6BFF);
  static const _lightScaffoldColor = Color(0xFFF4F7FB);
  static const _darkScaffoldColor = Color(0xFF0F131B);
  static const _themeRadius = 16.0;

  late final ThemeData _lightTheme = _buildTheme(Brightness.light);

  late final ThemeData _darkTheme = _buildTheme(Brightness.dark);

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _themeSeedColor,
      brightness: brightness,
    );
    final scaffoldBackgroundColor = brightness == Brightness.dark
        ? _darkScaffoldColor
        : _lightScaffoldColor;
    final inputFillColor = brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow;

    OutlineInputBorder inputBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(_themeRadius),
        borderSide: BorderSide(color: color),
      );
    }

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      canvasColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.72),
        ),
        border: inputBorder(colorScheme.outlineVariant),
        enabledBorder: inputBorder(colorScheme.outlineVariant),
        disabledBorder: inputBorder(colorScheme.outlineVariant),
        focusedBorder: inputBorder(colorScheme.primary),
        errorBorder: inputBorder(colorScheme.error),
        focusedErrorBorder: inputBorder(colorScheme.error),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_themeRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_themeRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_themeRadius - 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

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
            ({ThemeMode themeMode, bool developerMode, Locale? locale})
          >(
            selector: (_, controller) => (
              themeMode: controller.themeMode,
              developerMode: controller.developerMode,
              locale: controller.locale,
            ),
            builder: (context, usageSettings, child) {
              WalletLocalizationManager.instance.setLocale(
                usageSettings.locale,
              );
              return MaterialApp(
                title: 'Zero Wallet',
                onGenerateRoute: WalletRoutes.onGenerateRoute,
                theme: _lightTheme,
                darkTheme: _darkTheme,
                themeMode: usageSettings.themeMode,
                locale: usageSettings.locale,
                supportedLocales: WalletLocalizations.supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
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
