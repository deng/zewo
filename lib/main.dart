import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zero_wallet/wallet.dart';

import 'src/network_setup.dart';

Future<void> main() async {
  await bootstrapZeroWalletApp();
}

Future<void> bootstrapZeroWalletApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register network interceptor for hot/cold wallet mode switching.
  // No-op on web (dart:io not available).
  await setupNetworkInterceptor();

  // 初始化 AppLifecycleManager
  await AppLifecycleManager.instance.initialize();

  runApp(const ZeroWalletApp());
}

class ZeroWalletApp extends StatefulWidget {
  const ZeroWalletApp({super.key});

  @override
  State<ZeroWalletApp> createState() => _ZeroWalletAppState();
}

class _ZeroWalletAppState extends State<ZeroWalletApp>
    with WidgetsBindingObserver {
  static const MethodChannel _deepLinkMethodChannel = MethodChannel(
    'zero/deep_links',
  );
  static const EventChannel _deepLinkEventChannel = EventChannel(
    'zero/deep_links/events',
  );
  static const _themeSeedColor = Color(0xFF3D6BFF);
  static const _lightScaffoldColor = Color(0xFFF4F7FB);
  static const _darkScaffoldColor = Color(0xFF0F131B);
  static const _themeRadius = 16.0;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final WalletProvider _walletProvider;
  late final WalletConnectController _walletConnectController;
  late final UsageSettingsController _usageSettingsController;
  late final SecuritySettingsController _securitySettingsController;
  late final AppLockController _appLockController;
  StreamSubscription<dynamic>? _deepLinkSubscription;
  String? _consumedInitialDeepLink;
  String? _appliedLocalizationToken;
  int _handledWalletConnectNavigationSerial = 0;

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
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
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
    WidgetsBinding.instance.addObserver(this);
    _walletProvider = WalletProvider();
    _walletProvider.initialize();
    const walletConnectConfig = WalletConnectAppConfig(
      projectId: String.fromEnvironment(
        'WC_PROJECT_ID',
        defaultValue: '589379195ceab6e791dd510bf5feb122',
      ),
      redirectScheme: 'zerowallet',
      metadata: WalletConnectAppMetadata(
        name: 'Zero Wallet',
        description: 'Zero Wallet mobile app entry for WalletConnect flows.',
        url: 'https://github.com/deng/zero-wallet-dapp-connect',
        icons: <String>[
          'https://raw.githubusercontent.com/deng/zero-wallet-dapp-connect/main/assets/icon.png',
        ],
      ),
    );
    _walletConnectController = WalletConnectController(
      walletProvider: _walletProvider,
      config: walletConnectConfig,
      transportClient: walletConnectConfig.isConfigured
          ? ReownWalletConnectTransportClient()
          : const UnavailableWalletConnectTransportClient(
              reason:
                  'WalletConnect projectId is not configured. Rebuild with --dart-define=WC_PROJECT_ID=<your_project_id> to enable DApp connections.',
            ),
    );
    _walletConnectController.addListener(_handleWalletConnectChanged);
    _walletConnectController.initialize();
    _usageSettingsController = UsageSettingsController();
    _usageSettingsController.addListener(_handleUsageSettingsChanged);
    _usageSettingsController.initialize();
    _securitySettingsController = SecuritySettingsController();
    _securitySettingsController.initialize();
    _appLockController = AppLockController(
      securitySettingsController: _securitySettingsController,
      walletProvider: _walletProvider,
    );
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    _walletConnectController.removeListener(_handleWalletConnectChanged);
    _usageSettingsController.removeListener(_handleUsageSettingsChanged);
    _walletConnectController.dispose();
    _appLockController.dispose();
    _securitySettingsController.dispose();
    _usageSettingsController.dispose();
    _walletProvider.dispose();
    // 在应用关闭时释放 AppLifecycleManager 的资源
    AppLifecycleManager.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_usageSettingsController.language == AppLanguage.system) {
      _syncWalletLocalization(_usageSettingsController.locale);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLockController.handleAppLifecycleState(state);
  }

  void _handleUsageSettingsChanged() {
    _syncWalletLocalization(_usageSettingsController.locale);
  }

  Future<void> _listenForDeepLinks() async {
    try {
      final initialLink = await _deepLinkMethodChannel.invokeMethod<String>(
        'getInitialLink',
      );
      if (initialLink != null && initialLink.isNotEmpty) {
        _consumedInitialDeepLink = initialLink;
        await _walletConnectController.ingestPairingUri(
          initialLink,
          source: WalletConnectPairingSource.deepLink,
          navigateToHome: true,
        );
      }
    } catch (e) {
      debugPrint('[DeepLink] getInitialLink failed: $e');
    }

    _deepLinkSubscription = _deepLinkEventChannel
        .receiveBroadcastStream()
        .listen((event) {
          _handleDeepLinkEvent(event);
        }, onError: (e) {
          debugPrint('[DeepLink] event stream error: $e');
        });
  }

  Future<void> _handleDeepLinkEvent(dynamic event) async {
    if (event is! String || event.isEmpty) {
      return;
    }
    if (event == _consumedInitialDeepLink) {
      _consumedInitialDeepLink = null;
      return;
    }
    try {
      await _walletConnectController.ingestPairingUri(
        event,
        source: WalletConnectPairingSource.deepLink,
        navigateToHome: true,
      );
    } catch (e) {
      debugPrint('[DeepLink] ingest failed: $e');
    }
  }

  void _handleWalletConnectChanged() {
    final target = _walletConnectController.navigationTarget;
    if (target == null ||
        target.serial <= _handledWalletConnectNavigationSerial) {
      return;
    }
    _handledWalletConnectNavigationSerial = target.serial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        return;
      }
      switch (target.destination) {
        case WalletConnectNavigationDestination.home:
          navigator.pushNamed(WalletRoutes.walletConnectHome);
          break;
        case WalletConnectNavigationDestination.proposalApproval:
          navigator.pushNamed(
            WalletRoutes.walletConnectProposalApproval,
            arguments: WalletConnectProposalApprovalRouteArgs(
              proposalId: target.proposalId!,
            ),
          );
          break;
        case WalletConnectNavigationDestination.requestApproval:
          navigator.pushNamed(
            WalletRoutes.walletConnectRequestApproval,
            arguments: WalletConnectRequestApprovalRouteArgs(
              requestId: target.requestId!,
            ),
          );
          break;
      }
      _walletConnectController.clearNavigationTarget(target.serial);
    });
  }

  void _syncWalletLocalization(Locale? locale) {
    final nextToken = _localizationToken(locale);
    if (_appliedLocalizationToken == nextToken) {
      return;
    }
    _appliedLocalizationToken = nextToken;
    WalletLocalizationManager.instance.setLocale(locale);
  }

  String _localizationToken(Locale? locale) {
    if (locale != null) {
      return locale.toLanguageTag();
    }
    return 'system:${WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag()}';
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 来自 wallet 库的 WalletProvider
        ChangeNotifierProvider<WalletProvider>.value(value: _walletProvider),
        ChangeNotifierProvider<WalletConnectController>.value(
          value: _walletConnectController,
        ),
        ChangeNotifierProvider<UsageSettingsController>.value(
          value: _usageSettingsController,
        ),
        ChangeNotifierProvider<SecuritySettingsController>.value(
          value: _securitySettingsController,
        ),
        ChangeNotifierProvider<AppLockController>.value(
          value: _appLockController,
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
              return MaterialApp(
                navigatorKey: _navigatorKey,
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
                  final content = child ?? const SizedBox.shrink();
                  final locked = Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) => _appLockController.resetForegroundTimer(),
                    child: content,
                  );
                  return usageSettings.developerMode
                      ? Banner(
                          message: 'DEV',
                          location: BannerLocation.topEnd,
                          child: locked,
                        )
                      : locked;
                },
                home: const MainPage(),
              );
            },
          ),
    );
  }
}

