import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zero_wallet/wallet.dart';
import 'package:zero/main.dart' as app;
import 'test_wallet_config.dart';

const String kValidImportMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const String kSecondValidImportMnemonic =
    'legal winner thank year wave sausage worth useful legal winner thank yellow';
const String kInvalidChecksumMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon';
const String kValidAptTransferAddress =
    '0x1111111111111111111111111111111111111111111111111111111111111111';
const String kValidEvmTransferAddress =
    '0x1111111111111111111111111111111111111111';
const String kValidXrpTransferAddress = 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpAYe';
const String kBtcTestnetChainId =
    '000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943';
const String kBscTestnetChainId = '97';
const String kPolygonTestnetChainId = '80002';
const String kBaseTestnetChainId = '84532';
const String kArbitrumTestnetChainId = '421614';
const String kOptimismTestnetChainId = '11155420';
const String kDogeTestnetChainId = 'doge_testnet';
const String kBchTestnetChainId = 'bch_testnet';
const String kLtcTestnetChainId = 'ltc_testnet';
const String kTrxNileCustomChainId = 'trx_nile';
const String kTrxShastaCustomChainId = 'trx_shasta';
const MethodChannel kToastChannel = MethodChannel('PonnamKarthik/fluttertoast');
const String kUrlLauncherIosLaunchChannelName =
    'dev.flutter.pigeon.url_launcher_ios.UrlLauncherApi.launchUrl';

enum _UrlLauncherIosLaunchResult { success, failure, invalidUrl }

class _UrlLauncherIosPigeonCodec extends StandardMessageCodec {
  const _UrlLauncherIosPigeonCodec();

  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is _UrlLauncherIosLaunchResult) {
      buffer.putUint8(129);
      writeValue(buffer, value.index);
      return;
    }
    super.writeValue(buffer, value);
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129:
        final value = readValue(buffer) as int?;
        return value == null ? null : _UrlLauncherIosLaunchResult.values[value];
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

const MessageCodec<Object?> kUrlLauncherIosPigeonCodec =
    _UrlLauncherIosPigeonCodec();

bool get supportsExternalLaunchUrlCapture =>
    defaultTargetPlatform == TargetPlatform.iOS;

void configureIntegrationTest() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await SecureStorageService.clearAll();
  });

  tearDownAll(() async {
    await SecureStorageService.clearAll();
  });
}

Future<void> launchTestApp() async {
  await app.bootstrapZeroWalletApp();
}

Future<void> pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('Timed out waiting for $finder to become visible');
}

Future<void> tapAndPump(
  WidgetTester tester,
  Finder finder, {
  Duration settle = const Duration(milliseconds: 600),
}) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder);
  await tester.pump(settle);
}

Future<void> scrollFinderIntoView(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  double delta = 300,
}) async {
  if (finder.evaluate().isEmpty) {
    final scrollableFinder = scrollable ?? find.byType(Scrollable).first;
    expect(scrollableFinder, findsWidgets);
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: scrollableFinder,
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> scrollToAndTap(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  double delta = 300,
  Duration settle = const Duration(milliseconds: 600),
}) async {
  await scrollFinderIntoView(
    tester,
    finder,
    scrollable: scrollable,
    delta: delta,
  );
  expect(finder, findsOneWidget);
  await tester.tap(finder);
  await tester.pump(settle);
}

Future<void> unfocusAndPump(
  WidgetTester tester, {
  Duration settle = const Duration(milliseconds: 300),
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(settle);
}

Future<void> pumpUntilWalletHomeReady(
  WidgetTester tester, {
  String? walletName,
}) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('wallet_home_selector_button')),
  );
  await pumpUntilVisible(tester, find.byKey(const Key('bottom_nav_home')));
  if (walletName != null) {
    await pumpUntilVisible(tester, find.text(walletName));
  }
}

Future<void> waitForCurrentWalletBalanceGreaterThanZero(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(seconds: 1),
}) async {
  Future<bool> hasPositiveBalance(
    WalletProvider provider,
    String walletId,
  ) async {
    final balanceText =
        (await Future<String?>.value(
          provider.getWalletTotalBalance(walletId),
        ))?.trim() ??
        '';
    final balanceValue = double.tryParse(balanceText);
    return balanceValue != null && balanceValue > 0;
  }

  final deadline = DateTime.now().add(timeout);
  Object? lastSyncError;
  while (DateTime.now().isBefore(deadline)) {
    final provider = WalletProvider.getInstance();
    final wallet = provider?.currentWallet;
    if (provider != null && wallet != null) {
      if (await hasPositiveBalance(provider, wallet.id)) {
        return;
      }
      try {
        await BalanceSyncService.instance.syncWallet(wallet.id);
      } catch (e) {
        lastSyncError = e;
        debugPrint('Failed to sync wallet balance for ${wallet.id}: $e');
      }
      if (await hasPositiveBalance(provider, wallet.id)) {
        return;
      }
    }
    await tester.pump(step);
  }

  throw TestFailure(
    lastSyncError == null
        ? 'Timed out waiting for current wallet balance to sync'
        : 'Timed out waiting for current wallet balance to sync. '
              'Last sync error: $lastSyncError',
  );
}

Future<String> waitForCurrentWalletNativeAssetBalanceGreaterThanZero(
  WidgetTester tester, {
  required String symbol,
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(seconds: 1),
}) async {
  dynamic findNativeAsset(WalletProvider provider, WalletInfo wallet) {
    for (final candidate in provider.getWalletTokenAssets(wallet.id)) {
      if (candidate.symbol == symbol &&
          candidate.chainId == wallet.chainId &&
          candidate.isNative == true) {
        return candidate;
      }
    }
    return null;
  }

  final deadline = DateTime.now().add(timeout);
  Object? lastSyncError;
  while (DateTime.now().isBefore(deadline)) {
    final provider = WalletProvider.getInstance();
    final wallet = provider?.currentWallet;
    if (provider != null && wallet != null) {
      var asset = findNativeAsset(provider, wallet);
      final balanceValue = double.tryParse(asset?.balance ?? '');
      if (asset != null && balanceValue != null && balanceValue > 0) {
        return asset.balance;
      }
      try {
        await BalanceSyncService.instance.syncWallet(wallet.id);
      } catch (e) {
        lastSyncError = e;
        debugPrint(
          'Failed to sync native asset balance for ${wallet.id} ($symbol): $e',
        );
      }
      asset = findNativeAsset(provider, wallet);
      final refreshedBalanceValue = double.tryParse(asset?.balance ?? '');
      if (asset != null &&
          refreshedBalanceValue != null &&
          refreshedBalanceValue > 0) {
        return asset.balance;
      }
    }
    await tester.pump(step);
  }

  throw TestFailure(
    lastSyncError == null
        ? 'Timed out waiting for current wallet native asset $symbol '
              'balance to sync'
        : 'Timed out waiting for current wallet native asset $symbol '
              'balance to sync. Last sync error: $lastSyncError',
  );
}

Future<String> waitForCurrentWalletNativeAssetBalanceGreaterThanZeroForChain(
  WidgetTester tester, {
  required String chainId,
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(seconds: 1),
}) async {
  dynamic findNativeAsset(WalletProvider provider, WalletInfo wallet) {
    for (final candidate in provider.getWalletTokenAssets(wallet.id)) {
      if (candidate.chainId == chainId && candidate.isNative == true) {
        return candidate;
      }
    }
    return null;
  }

  final deadline = DateTime.now().add(timeout);
  Object? lastSyncError;
  while (DateTime.now().isBefore(deadline)) {
    final provider = WalletProvider.getInstance();
    final wallet = provider?.currentWallet;
    if (provider != null && wallet != null) {
      var asset = findNativeAsset(provider, wallet);
      final balanceValue = double.tryParse(asset?.balance ?? '');
      if (asset != null && balanceValue != null && balanceValue > 0) {
        return asset.balance;
      }
      try {
        await BalanceSyncService.instance.syncWallet(wallet.id);
      } catch (e) {
        lastSyncError = e;
        debugPrint(
          'Failed to sync native asset balance for ${wallet.id} ($chainId): $e',
        );
      }
      asset = findNativeAsset(provider, wallet);
      final refreshedBalanceValue = double.tryParse(asset?.balance ?? '');
      if (asset != null &&
          refreshedBalanceValue != null &&
          refreshedBalanceValue > 0) {
        return asset.balance;
      }
    }
    await tester.pump(step);
  }

  throw TestFailure(
    lastSyncError == null
        ? 'Timed out waiting for current wallet native asset balance for '
              '$chainId to sync'
        : 'Timed out waiting for current wallet native asset balance for '
              '$chainId to sync. Last sync error: $lastSyncError',
  );
}

Future<AssetActivityRecord> waitForWalletActivityByTxHash(
  WidgetTester tester, {
  required String walletId,
  required String txHash,
  AssetActivityStatus? status,
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 500),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final activities = WalletProvider.getInstance()?.getWalletAssetActivities(
      walletId,
    );
    if (activities != null) {
      for (final activity in activities) {
        if (activity.txHash == txHash &&
            (status == null || activity.status == status)) {
          return activity;
        }
      }
    }
    await tester.pump(step);
  }

  throw TestFailure(
    'Timed out waiting for wallet activity $txHash'
    '${status == null ? '' : ' with status ${status.name}'} in wallet $walletId',
  );
}

Future<void> expectTextVisible(WidgetTester tester, String text) async {
  await pumpUntilVisible(tester, find.text(text));
  expect(find.text(text), findsOneWidget);
}

Future<void> expectWalletHome(
  WidgetTester tester, {
  required String walletName,
}) async {
  await pumpUntilWalletHomeReady(tester, walletName: walletName);
  expect(find.text('钱包'), findsOneWidget);
  expect(find.text('资产'), findsOneWidget);
}

Future<void> expectCreateWalletPageVisible(WidgetTester tester) async {
  await expectTextVisible(tester, '创建钱包');
}

Future<void> openReceiveFromWalletHome(WidgetTester tester) async {
  await tapAndPump(tester, find.byKey(const Key('wallet_home_receive_button')));
}

Future<void> openTransferFromWalletHome(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('wallet_home_transfer_button')),
  );
}

Future<void> openWalletDetailFromHome(WidgetTester tester) async {
  await tapAndPump(tester, find.byKey(const Key('wallet_home_detail_button')));
}

Future<void> openHdManageFromWalletDetail(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('wallet_detail_hd_manage_button')),
  );
}

Future<void> openBackupMnemonicFromHdManage(WidgetTester tester) async {
  await tapAndPump(tester, find.byKey(const Key('backup_mnemonic_menu_item')));
}

Future<void> expectPostImportPromptVisible(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('post_import_sheet_title')),
  );
  expect(find.byKey(const Key('post_import_sheet_title')), findsOneWidget);
  expect(find.text('导入成功'), findsOneWidget);
}

void expectPostImportPromptHidden() {
  expect(find.byKey(const Key('post_import_sheet_title')), findsNothing);
}

Future<void> expectImportWalletError(
  WidgetTester tester,
  String message,
) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('import_wallet_error_text')),
  );
  expect(find.text(message), findsOneWidget);
}

Future<void> expectWalletReceivePage(
  WidgetTester tester, {
  String? address,
}) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('wallet_receive_page_title')),
  );
  expect(find.byKey(const Key('wallet_receive_qr_code')), findsOneWidget);
  expect(find.byKey(const Key('wallet_receive_address_text')), findsOneWidget);
  expect(
    find.byKey(const Key('wallet_receive_set_amount_button')),
    findsOneWidget,
  );
  if (address != null) {
    expect(find.text(address), findsOneWidget);
  }
}

Future<void> expectBackupMnemonicPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('backup_mnemonic_page_title')),
  );
  expect(
    find.byKey(const Key('backup_mnemonic_instruction_title')),
    findsOneWidget,
  );
  expect(find.byKey(const Key('backup_mnemonic_word_0')), findsOneWidget);
  expect(find.byKey(const Key('backup_mnemonic_next_button')), findsOneWidget);
}

Future<void> completeBackupMnemonicVerification(
  WidgetTester tester, {
  required List<String> mnemonicWords,
}) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('backup_mnemonic_next_button')),
  );
  await expectTextVisible(tester, '验证助记词');

  for (var position = 0; position < 3; position++) {
    final slotFinder = find.byKey(
      Key('backup_mnemonic_verification_slot_$position'),
    );
    final slotText = tester.widget<Text>(slotFinder).data!;
    final match = RegExp(r'第(\d+)个').firstMatch(slotText);
    expect(match, isNotNull);

    final wordIndex = int.parse(match!.group(1)!) - 1;
    final targetWord = mnemonicWords[wordIndex];
    var tapped = false;

    for (var optionIndex = 0; optionIndex < 12; optionIndex++) {
      final optionFinder = find.byKey(
        Key('backup_mnemonic_option_$optionIndex'),
      );
      if (optionFinder.evaluate().isEmpty) {
        continue;
      }

      final hasWord = find
          .descendant(of: optionFinder, matching: find.text(targetWord))
          .evaluate()
          .isNotEmpty;
      if (!hasWord) {
        continue;
      }

      final optionWidget = tester.widget<GestureDetector>(optionFinder);
      if (optionWidget.onTap == null) {
        continue;
      }

      await tapAndPump(tester, optionFinder);
      tapped = true;
      break;
    }

    expect(tapped, isTrue, reason: '未找到可点击的助记词选项: $targetWord');
  }
}

Future<void> setReceiveAmount(WidgetTester tester, String amount) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('wallet_receive_set_amount_button')),
  );
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('wallet_receive_amount_dialog_title')),
  );
  await tester.enterText(
    find.byKey(const Key('wallet_receive_amount_field')),
    amount,
  );
  await tapAndPump(
    tester,
    find.byKey(const Key('wallet_receive_amount_confirm_button')),
  );
}

Future<void> unlockBackupMnemonic(
  WidgetTester tester, {
  String password = 'Passw0rd!',
}) async {
  await unlockPasswordPrompt(tester, password: password);
}

Future<void> expectValidationError(WidgetTester tester, String message) async {
  await expectTextVisible(tester, message);
}

Future<void> expectValidationErrors(
  WidgetTester tester,
  List<String> messages,
) async {
  for (final message in messages) {
    await expectValidationError(tester, message);
  }
}

Future<void> openCreateWalletFromHome(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('home_create_wallet_button')),
  );
  await tapAndPump(tester, find.byKey(const Key('home_create_wallet_button')));
}

Future<void> openImportWalletFromHome(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('home_import_wallet_button')),
  );
  await tapAndPump(tester, find.byKey(const Key('home_import_wallet_button')));
}

Future<void> openWalletSelector(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('wallet_home_selector_button')),
  );
  await tapAndPump(
    tester,
    find.byKey(const Key('wallet_home_selector_button')),
  );
}

Future<void> openWalletSelectorAddMenu(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('wallet_selector_add_button')),
  );
  await tapAndPump(tester, find.byKey(const Key('wallet_selector_add_button')));
}

Future<void> chooseCreateWalletFromSelector(WidgetTester tester) async {
  await openWalletSelectorAddMenu(tester);
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('wallet_selector_add_create_button')),
  );
  await tapAndPump(
    tester,
    find.byKey(const Key('wallet_selector_add_create_button')),
  );
}

Future<void> chooseImportWalletFromSelector(WidgetTester tester) async {
  await openWalletSelectorAddMenu(tester);
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('wallet_selector_add_import_button')),
  );
  await tapAndPump(
    tester,
    find.byKey(const Key('wallet_selector_add_import_button')),
  );
}

Future<void> chooseViewWalletFromPostImportPrompt(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('post_import_view_wallet_button')),
  );
  await tapAndPump(
    tester,
    find.byKey(const Key('post_import_view_wallet_button')),
  );
}

Future<void> chooseAddNetworksFromPostImportPrompt(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('post_import_add_networks_button')),
  );
  await tapAndPump(
    tester,
    find.byKey(const Key('post_import_add_networks_button')),
  );
}

Future<void> fillCreateWalletForm(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
  String? confirmPassword = 'Passw0rd!',
}) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('create_wallet_name_field')),
  );

  await tester.enterText(
    find.byKey(const Key('create_wallet_name_field')),
    walletName,
  );
  await tester.enterText(
    find.byKey(const Key('create_wallet_password_field')),
    password,
  );
  if (confirmPassword != null) {
    await tester.enterText(
      find.byKey(const Key('create_wallet_confirm_password_field')),
      confirmPassword,
    );
  }

  await unfocusAndPump(tester);
}

Future<void> fillImportWalletForm(
  WidgetTester tester, {
  required String walletName,
  String mnemonic = kValidImportMnemonic,
  String password = 'Passw0rd!',
  String? confirmPassword = 'Passw0rd!',
}) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('import_wallet_name_field')),
  );

  await tester.enterText(
    find.byKey(const Key('import_wallet_name_field')),
    walletName,
  );
  await tester.enterText(
    find.byKey(const Key('import_wallet_mnemonic_field')),
    mnemonic,
  );
  await tester.enterText(
    find.byKey(const Key('import_wallet_password_field')),
    password,
  );
  if (confirmPassword != null) {
    await tester.enterText(
      find.byKey(const Key('import_wallet_confirm_password_field')),
      confirmPassword,
    );
  }

  await unfocusAndPump(tester);
}

Future<void> submitCreateWallet(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('create_wallet_submit_button')),
    settle: const Duration(seconds: 1),
  );
}

Future<void> submitImportWallet(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('import_wallet_submit_button')),
    settle: const Duration(seconds: 1),
  );
}

Future<void> createWalletFromHome(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
  String? confirmPassword = 'Passw0rd!',
}) async {
  await openCreateWalletFromHome(tester);
  await fillCreateWalletForm(
    tester,
    walletName: walletName,
    password: password,
    confirmPassword: confirmPassword,
  );
  await submitCreateWallet(tester);
}

Future<void> importWalletFromHome(
  WidgetTester tester, {
  required String walletName,
  String mnemonic = kValidImportMnemonic,
  String password = 'Passw0rd!',
  String? confirmPassword = 'Passw0rd!',
}) async {
  await openImportWalletFromHome(tester);
  await fillImportWalletForm(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
    confirmPassword: confirmPassword,
  );
  await submitImportWallet(tester);
}

Future<void> createWalletFromSelector(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
  String? confirmPassword = 'Passw0rd!',
}) async {
  await openWalletSelector(tester);
  await chooseCreateWalletFromSelector(tester);
  await fillCreateWalletForm(
    tester,
    walletName: walletName,
    password: password,
    confirmPassword: confirmPassword,
  );
  await submitCreateWallet(tester);
}

Future<void> importWalletFromSelector(
  WidgetTester tester, {
  required String walletName,
  String mnemonic = kValidImportMnemonic,
  String password = 'Passw0rd!',
  String? confirmPassword = 'Passw0rd!',
}) async {
  await openWalletSelector(tester);
  await chooseImportWalletFromSelector(tester);
  await fillImportWalletForm(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
    confirmPassword: confirmPassword,
  );
  await submitImportWallet(tester);
}

Future<void> importWalletThenViewWallet(
  WidgetTester tester, {
  required String walletName,
  String mnemonic = kValidImportMnemonic,
  String password = 'Passw0rd!',
  String? confirmPassword = 'Passw0rd!',
}) async {
  await importWalletFromHome(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
    confirmPassword: confirmPassword,
  );
  await chooseViewWalletFromPostImportPrompt(tester);
}

Future<void> importWalletThenAddNetworks(
  WidgetTester tester, {
  required String walletName,
  String mnemonic = kValidImportMnemonic,
  String password = 'Passw0rd!',
  String? confirmPassword = 'Passw0rd!',
}) async {
  await importWalletFromHome(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
    confirmPassword: confirmPassword,
  );
  await chooseAddNetworksFromPostImportPrompt(tester);
}

Future<void> openAddWalletFromHdManage(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('hd_management_add_wallet_tile')),
  );
}

Future<void> createWalletAndAddHdWallet(
  WidgetTester tester, {
  required String walletName,
  required String chainId,
  String password = 'Passw0rd!',
}) async {
  await createWalletFromHome(
    tester,
    walletName: walletName,
    password: password,
  );
  await expectWalletHome(tester, walletName: walletName);

  await openWalletDetailFromHome(tester);
  await expectTextVisible(tester, '钱包详情');

  await openHdManageFromWalletDetail(tester);
  await expectTextVisible(tester, '添加钱包');

  await openAddWalletFromHdManage(tester);
  await expectTextVisible(tester, '添加钱包');

  await addHdWalletByChainId(tester, chainId: chainId, password: password);
  await pumpUntilWalletHomeReady(tester);
}

Future<void> createWalletAndAddAptTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: 'apt_testnet',
    password: password,
  );
}

Future<void> createWalletAndAddBtcTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kBtcTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddDogeTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kDogeTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddBchTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kBchTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddLtcTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kLtcTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddEthSepoliaWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: '11155111',
    password: password,
  );
}

Future<void> createWalletAndAddBscTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kBscTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddPolygonTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kPolygonTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddBaseTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kBaseTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddArbitrumTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kArbitrumTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddOptimismTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: kOptimismTestnetChainId,
    password: password,
  );
}

Future<void> createWalletAndAddXrpTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: 'xrp_testnet',
    password: password,
  );
}

Future<void> createWalletAndAddSolDevnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: 'sol_devnet',
    password: password,
  );
}

Future<void> createWalletAndAddSuiTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: 'sui_testnet',
    password: password,
  );
}

Future<void> createWalletAndAddTonTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: 'ton_testnet',
    password: password,
  );
}

String trxChainIdForIntegrationNetwork(String network) => switch (network) {
  kTrxNetworkMainnet => 'trx_mainnet',
  kTrxNetworkShasta => kTrxShastaCustomChainId,
  _ => kTrxNileCustomChainId,
};

String trxExplorerTxBaseUrlForIntegrationNetwork(String network) =>
    switch (network) {
      kTrxNetworkMainnet => 'https://tronscan.org/#/transaction/',
      kTrxNetworkShasta => 'https://shasta.tronscan.org/#/transaction/',
      _ => 'https://nile.tronscan.org/#/transaction/',
    };

Future<void> _ensureTrxCustomNetwork({required String network}) async {
  // Intentionally a no-op: Nile and Shasta are built-in TRON networks in the
  // app now, so test setup does not need an extra registration step.
  debugPrint('TRX network "$network" already available; no setup required.');
  return;
}

Future<void> createWalletAndAddTrxWalletForNetwork(
  WidgetTester tester, {
  required String network,
  required String walletName,
  String password = 'Passw0rd!',
}) async {
  await _ensureTrxCustomNetwork(network: network);
  await createWalletAndAddHdWallet(
    tester,
    walletName: walletName,
    chainId: trxChainIdForIntegrationNetwork(network),
    password: password,
  );
}

Future<void> importWalletAndAddAptTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: 'apt_testnet',
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddBtcTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kBtcTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddDogeTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kDogeTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddBchTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kBchTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddLtcTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kLtcTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddEthSepoliaWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(tester, chainId: '11155111', password: password);
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddBscTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kBscTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddPolygonTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kPolygonTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddBaseTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kBaseTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddArbitrumTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kArbitrumTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddOptimismTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: kOptimismTestnetChainId,
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddXrpTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: 'xrp_testnet',
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddSolDevnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(tester, chainId: 'sol_devnet', password: password);
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddSuiTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: 'sui_testnet',
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddTonTestnetWallet(
  WidgetTester tester, {
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: 'ton_testnet',
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> importWalletAndAddTrxWalletForNetwork(
  WidgetTester tester, {
  required String network,
  required String walletName,
  required String mnemonic,
  String password = 'Passw0rd!',
}) async {
  await _ensureTrxCustomNetwork(network: network);
  await importWalletThenAddNetworks(
    tester,
    walletName: walletName,
    mnemonic: mnemonic,
    password: password,
  );
  await addHdWalletByChainId(
    tester,
    chainId: trxChainIdForIntegrationNetwork(network),
    password: password,
  );
  await pumpUntilWalletHomeReady(tester);
}

Future<void> expectAptTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('apt_transfer_page_title')),
  );
  expect(find.byKey(const Key('apt_transfer_address_field')), findsOneWidget);
  expect(find.byKey(const Key('apt_transfer_amount_field')), findsOneWidget);
  expect(find.byKey(const Key('apt_transfer_submit_button')), findsOneWidget);
}

Future<void> expectBtcTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('输入或粘贴钱包地址'));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '输入或粘贴钱包地址',
    ),
    findsOneWidget,
  );
  expect(find.text('确定'), findsWidgets);
}

Future<void> expectDogeTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('发送 DOGE'));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '请输入 DOGE 地址',
    ),
    findsOneWidget,
  );
  expect(find.text('发送'), findsOneWidget);
}

Future<void> expectBchTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('发送 BCH'));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '请输入 BCH 地址',
    ),
    findsOneWidget,
  );
  expect(find.text('发送'), findsOneWidget);
}

Future<void> expectLtcTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('发送 Testnet LTC'));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '请输入 LTC 地址',
    ),
    findsOneWidget,
  );
  expect(find.text('发送'), findsOneWidget);
}

Future<void> expectXrpTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('xrp_transfer_page_title')),
  );
  expect(find.byKey(const Key('xrp_transfer_address_field')), findsOneWidget);
  expect(find.byKey(const Key('xrp_transfer_amount_field')), findsOneWidget);
  expect(
    find.byKey(const Key('xrp_transfer_destination_tag_field')),
    findsOneWidget,
  );
  expect(find.byKey(const Key('xrp_transfer_submit_button')), findsOneWidget);
}

Future<void> expectEvmTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('evm_transfer_page_title')),
  );
  expect(find.byKey(const Key('evm_transfer_address_field')), findsOneWidget);
  expect(find.byKey(const Key('evm_transfer_amount_field')), findsOneWidget);
  expect(find.byKey(const Key('evm_transfer_submit_button')), findsOneWidget);
}

Future<void> expectTrxTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('TRX 转账'));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '请输入 TRON 地址',
    ),
    findsOneWidget,
  );
  expect(
    find.byWidgetPredicate(
      (widget) => widget is FilledButton && widget.child is Text,
    ),
    findsWidgets,
  );
  expect(find.text('确定'), findsOneWidget);
}

Future<void> expectSolTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('SOL 转账'));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '请输入 Solana 地址',
    ),
    findsOneWidget,
  );
  expect(find.text('确定'), findsOneWidget);
}

Future<void> expectSuiTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('发送 SUI'));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '请输入 Sui 地址',
    ),
    findsOneWidget,
  );
  expect(find.text('发送'), findsOneWidget);
}

Future<void> expectTonTransferPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('TON 转账'));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'EQ... 或 0:...',
    ),
    findsOneWidget,
  );
  expect(find.text('发送 TON'), findsOneWidget);
}

Future<void> expectAptTransactionStatusPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('apt_transaction_status_page_title')),
  );
  expect(
    find.byKey(const Key('apt_transaction_status_message')),
    findsOneWidget,
  );
}

Future<void> expectBtcTransactionStatusPage(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await pumpUntilVisible(tester, find.text('BTC 交易状态'), timeout: timeout);
  expect(find.textContaining('交易'), findsWidgets);
}

Future<void> expectDogeTransactionStatusPage(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await pumpUntilVisible(tester, find.text('DOGE 交易状态'), timeout: timeout);
  expect(find.textContaining('交易'), findsWidgets);
}

Future<void> expectBchTransactionStatusPage(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await pumpUntilVisible(tester, find.text('BCH 交易状态'), timeout: timeout);
  expect(find.textContaining('交易'), findsWidgets);
}

Future<void> expectLtcTransactionStatusPage(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await pumpUntilVisible(tester, find.text('LTC 交易状态'), timeout: timeout);
  expect(find.textContaining('交易'), findsWidgets);
}

Future<void> expectXrpTransactionStatusPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('xrp_transaction_status_page_title')),
  );
  expect(
    find.byKey(const Key('xrp_transaction_status_message')),
    findsOneWidget,
  );
}

Future<void> expectEvmTransactionStatusPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('evm_transaction_status_page_title')),
  );
  expect(
    find.byKey(const Key('evm_transaction_status_message')),
    findsOneWidget,
  );
}

Future<void> expectTrxTransactionStatusPage(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('TRX 转账状态'));
  expect(find.textContaining('交易'), findsWidgets);
}

Future<void> expectSolTransactionStatusPage(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await pumpUntilVisible(tester, find.text('SOL 转账状态'), timeout: timeout);
  expect(find.textContaining('交易'), findsWidgets);
}

Future<void> expectSuiTransactionStatusPage(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await pumpUntilVisible(tester, find.text('SUI 转账状态'), timeout: timeout);
  expect(find.textContaining('交易'), findsWidgets);
}

Future<void> expectTonTransactionStatusPage(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await pumpUntilVisible(tester, find.text('TON 交易结果'), timeout: timeout);
  expect(find.textContaining('消息哈希'), findsOneWidget);
}

Future<String> readAptTransactionHash(WidgetTester tester) async {
  final finder = find.byKey(const Key('apt_transaction_status_tx_hash_value'));
  await pumpUntilVisible(tester, finder);
  return tester.widget<Text>(finder).data!;
}

Future<String> readBtcTransactionHash(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('BTC 交易状态'));
  final textElements = find.byType(Text).evaluate();
  final hashPattern = RegExp(r'^[A-Fa-f0-9]{64}$');
  for (final element in textElements) {
    final widget = element.widget;
    if (widget is Text) {
      final data = widget.data?.trim();
      if (data != null && hashPattern.hasMatch(data)) {
        return data;
      }
    }
  }
  throw TestFailure('Unable to find BTC transaction hash on status page');
}

Future<String> readDogeTransactionHash(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('DOGE 交易状态'));
  final textElements = find.byType(Text).evaluate();
  final hashPattern = RegExp(r'^[A-Fa-f0-9]{64}$');
  for (final element in textElements) {
    final widget = element.widget;
    if (widget is Text) {
      final data = widget.data?.trim();
      if (data != null && hashPattern.hasMatch(data)) {
        return data;
      }
    }
  }
  throw TestFailure('Unable to find DOGE transaction hash on status page');
}

Future<String> readBchTransactionHash(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('BCH 交易状态'));
  final textElements = find.byType(Text).evaluate();
  final hashPattern = RegExp(r'^[A-Fa-f0-9]{64}$');
  for (final element in textElements) {
    final widget = element.widget;
    if (widget is Text) {
      final data = widget.data?.trim();
      if (data != null && hashPattern.hasMatch(data)) {
        return data;
      }
    }
  }
  throw TestFailure('Unable to find BCH transaction hash on status page');
}

Future<String> readLtcTransactionHash(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('LTC 交易状态'));
  final textElements = find.byType(Text).evaluate();
  final hashPattern = RegExp(r'^[A-Fa-f0-9]{64}$');
  for (final element in textElements) {
    final widget = element.widget;
    if (widget is Text) {
      final data = widget.data?.trim();
      if (data != null && hashPattern.hasMatch(data)) {
        return data;
      }
    }
  }
  throw TestFailure('Unable to find LTC transaction hash on status page');
}

Future<String> readXrpTransactionHash(WidgetTester tester) async {
  final finder = find.byKey(const Key('xrp_transaction_status_tx_hash_value'));
  await pumpUntilVisible(tester, finder);
  return tester.widget<SelectableText>(finder).data!;
}

Future<String> readEvmTransactionHash(WidgetTester tester) async {
  final finder = find.byKey(const Key('evm_transaction_status_tx_hash_value'));
  await pumpUntilVisible(tester, finder);
  return tester.widget<Text>(finder).data!;
}

Future<String> readTrxTransactionHash(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('TRX 转账状态'));
  final textElements = find.byType(Text).evaluate();
  final hashPattern = RegExp(r'^[A-Fa-f0-9]{64}$');
  for (final element in textElements) {
    final widget = element.widget;
    if (widget is Text) {
      final data = widget.data?.trim();
      if (data != null && hashPattern.hasMatch(data)) {
        return data;
      }
    }
  }
  throw TestFailure('Unable to find TRX transaction hash on status page');
}

Future<String> readSolTransactionSignature(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('SOL 转账状态'));
  final textElements = find.byType(Text).evaluate();
  final signaturePattern = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{80,100}$');
  for (final element in textElements) {
    final widget = element.widget;
    if (widget is Text) {
      final data = widget.data?.trim();
      if (data != null && signaturePattern.hasMatch(data)) {
        return data;
      }
    }
  }
  throw TestFailure('Unable to find SOL transaction signature on status page');
}

Future<String> readSuiTransactionDigest(WidgetTester tester) async {
  const labelText = '交易 Digest';
  await pumpUntilVisible(tester, find.text(labelText));
  final rowFinder = find.ancestor(
    of: find.text(labelText),
    matching: find.byType(Row),
  );
  final digestPattern = RegExp(
    r'^(0x[0-9a-fA-F]{64}|[1-9A-HJ-NP-Za-km-z]{20,})$',
  );
  final valueElements = find
      .descendant(
        of: rowFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Text || widget is SelectableText,
        ),
      )
      .evaluate();

  for (final element in valueElements) {
    final widget = element.widget;
    final data = switch (widget) {
      Text() => widget.data?.trim() ?? widget.textSpan?.toPlainText().trim(),
      SelectableText() =>
        widget.data?.trim() ?? widget.textSpan?.toPlainText().trim(),
      _ => null,
    };
    if (data != null && data != labelText && digestPattern.hasMatch(data)) {
      return data;
    }
  }
  throw TestFailure('Unable to find Sui transaction digest on status page');
}

Future<String> readTonTransactionLookupHash(WidgetTester tester) async {
  await pumpUntilVisible(tester, find.text('TON 交易结果'));
  const preferredKeys = <Key>[
    Key('ton_transaction_status_final_hash_value'),
    Key('ton_transaction_status_normalized_lookup_hash_value'),
    Key('ton_transaction_status_lookup_hash_value'),
  ];
  final deadline = tester.binding.clock.fromNowBy(const Duration(seconds: 5));
  while (true) {
    for (final key in preferredKeys) {
      final finder = find.byKey(key);
      if (finder.evaluate().isEmpty) {
        continue;
      }
      final widget = tester.widget<SelectableText>(finder);
      final data = widget.data?.trim();
      if (data != null && data.isNotEmpty) {
        return data;
      }
    }

    if (!tester.binding.clock.now().isBefore(deadline)) {
      break;
    }

    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure(
    'Unable to find TON transaction lookup hash on status page',
  );
}

Future<void> openAptTransactionLookupFromStatus(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('apt_transaction_status_lookup_button')),
  );
}

Future<void> openBtcExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('在浏览器中查看').first);
}

Future<void> openDogeExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('在浏览器中查看').first);
}

Future<void> openBchExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('在浏览器中查看').first);
}

Future<void> openLtcExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('在浏览器中查看').first);
}

Future<void> openAptExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(
    tester,
    find.byKey(const Key('apt_transaction_status_open_explorer_button')),
  );
}

Future<void> openXrpTransactionLookupFromStatus(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('xrp_transaction_status_lookup_button')),
  );
}

Future<void> openXrpExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(
    tester,
    find.byKey(const Key('xrp_transaction_status_open_explorer_button')),
  );
}

Future<void> openEvmTransactionLookupFromStatus(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('evm_transaction_status_lookup_button')),
  );
}

Future<void> openEvmExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(
    tester,
    find.byKey(const Key('evm_transaction_status_open_explorer_button')),
  );
}

Future<void> openTrxExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('在浏览器中查看'));
}

Future<void> openSuiExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('在浏览器中查看'));
}

Future<void> openTonExplorerFromStatusPage(WidgetTester tester) async {
  await scrollToAndTap(
    tester,
    find.byKey(const Key('ton_transaction_status_open_explorer_button')),
  );
}

Future<void> returnToWalletHomeFromStatusPage(WidgetTester tester) async {
  final homeFinder = find.byKey(const Key('wallet_home_selector_button'));
  for (var i = 0; i < 4; i++) {
    if (homeFinder.evaluate().isNotEmpty) {
      await pumpUntilWalletHomeReady(tester);
      return;
    }
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 600));
  }
  await pumpUntilWalletHomeReady(tester);
}

Future<void> openAssetDetailFromWalletHome(
  WidgetTester tester, {
  required String chainId,
  required String symbol,
}) async {
  final assetFinder = find.byKey(Key('wallet_home_asset_${chainId}_$symbol'));
  await pumpUntilVisible(tester, assetFinder);
  await tapAndPump(tester, assetFinder);
}

Future<void> expectAssetDetailPage(
  WidgetTester tester, {
  required String symbol,
}) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('asset_detail_page_title')),
  );
  expect(find.byKey(const Key('asset_detail_page_title')), findsOneWidget);
  expect(find.text(symbol), findsWidgets);
}

Future<void> openAllActivityFromAssetDetail(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('asset_detail_view_all_activity_button')),
  );
}

Future<void> openRecentAssetDetailActivityByTxHash(
  WidgetTester tester, {
  required String txHash,
}) async {
  final activityFinder = find.byKey(
    Key('asset_detail_recent_activity_$txHash'),
  );
  await pumpUntilVisible(tester, activityFinder);
  await tapAndPump(tester, activityFinder);
}

Future<void> expectAssetActivityPage(
  WidgetTester tester, {
  required String symbol,
}) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('asset_activity_page_title')),
  );
  expect(find.text('$symbol 活动'), findsOneWidget);
}

Future<void> openAssetActivityByTxHash(
  WidgetTester tester, {
  required String txHash,
}) async {
  final activityFinder = find.byKey(Key('asset_activity_item_$txHash'));
  await pumpUntilVisible(tester, activityFinder);
  await tapAndPump(tester, activityFinder);
}

Future<void> expectAptTransactionLookupPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('apt_transaction_lookup_page_title')),
  );
  expect(
    find.byKey(const Key('apt_transaction_lookup_hash_field')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('apt_transaction_lookup_submit_button')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('apt_transaction_lookup_open_explorer_button')),
    findsOneWidget,
  );
}

Future<void> expectXrpTransactionLookupPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('xrp_transaction_lookup_page_title')),
  );
  expect(
    find.byKey(const Key('xrp_transaction_lookup_hash_field')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('xrp_transaction_lookup_submit_button')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('xrp_transaction_lookup_open_explorer_button')),
    findsOneWidget,
  );
}

Future<void> expectEvmTransactionLookupPage(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('evm_transaction_lookup_page_title')),
  );
  expect(
    find.byKey(const Key('evm_transaction_lookup_hash_field')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('evm_transaction_lookup_submit_button')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('evm_transaction_lookup_open_explorer_button')),
    findsOneWidget,
  );
}

Future<void> lookupAptTransactionByHash(
  WidgetTester tester, {
  required String txHash,
}) async {
  await tester.enterText(
    find.byKey(const Key('apt_transaction_lookup_hash_field')),
    txHash,
  );
  await unfocusAndPump(tester);
  await tapAndPump(
    tester,
    find.byKey(const Key('apt_transaction_lookup_submit_button')),
  );
}

Future<void> expectAptLookupHashFieldValue(
  WidgetTester tester, {
  required String txHash,
}) async {
  final field = tester.widget<TextField>(
    find.byKey(const Key('apt_transaction_lookup_hash_field')),
  );
  expect(field.controller?.text, txHash);
}

Future<void> openAptExplorerFromLookupPage(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('apt_transaction_lookup_open_explorer_button')),
  );
}

Future<void> lookupXrpTransactionByHash(
  WidgetTester tester, {
  required String txHash,
}) async {
  await tester.enterText(
    find.byKey(const Key('xrp_transaction_lookup_hash_field')),
    txHash,
  );
  await unfocusAndPump(tester);
  await tapAndPump(
    tester,
    find.byKey(const Key('xrp_transaction_lookup_submit_button')),
  );
}

Future<void> expectXrpLookupHashFieldValue(
  WidgetTester tester, {
  required String txHash,
}) async {
  final field = tester.widget<TextField>(
    find.byKey(const Key('xrp_transaction_lookup_hash_field')),
  );
  expect(field.controller?.text, txHash);
}

Future<void> lookupEvmTransactionByHash(
  WidgetTester tester, {
  required String txHash,
}) async {
  await tester.enterText(
    find.byKey(const Key('evm_transaction_lookup_hash_field')),
    txHash,
  );
  await unfocusAndPump(tester);
  await tapAndPump(
    tester,
    find.byKey(const Key('evm_transaction_lookup_submit_button')),
  );
}

Future<void> expectEvmLookupHashFieldValue(
  WidgetTester tester, {
  required String txHash,
}) async {
  final field = tester.widget<TextField>(
    find.byKey(const Key('evm_transaction_lookup_hash_field')),
  );
  expect(field.controller?.text, txHash);
}

Future<void> openXrpExplorerFromLookupPage(WidgetTester tester) async {
  await scrollToAndTap(
    tester,
    find.byKey(const Key('xrp_transaction_lookup_open_explorer_button')),
  );
}

Future<void> openEvmExplorerFromLookupPage(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('evm_transaction_lookup_open_explorer_button')),
  );
}

Future<void> fillAptTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  await tester.enterText(
    find.byKey(const Key('apt_transfer_address_field')),
    address,
  );
  await tester.enterText(
    find.byKey(const Key('apt_transfer_amount_field')),
    amount,
  );
  await unfocusAndPump(tester);
}

Future<void> fillBtcTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  final addressField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '输入或粘贴钱包地址',
  );
  final amountField = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == '0',
  );
  await tester.enterText(addressField, address);
  await tester.enterText(amountField, amount);
  await unfocusAndPump(tester);
}

Future<void> fillBchTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  final addressField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '请输入 BCH 地址',
  );
  final amountField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '请输入 BCH 金额',
  );
  await tester.enterText(addressField, address);
  await tester.enterText(amountField, amount);
  await unfocusAndPump(tester);
}

Future<void> fillDogeTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  final addressField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '请输入 DOGE 地址',
  );
  final amountField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '请输入 DOGE 金额',
  );
  await tester.enterText(addressField, address);
  await tester.enterText(amountField, amount);
  await unfocusAndPump(tester);
}

Future<void> fillLtcTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  final addressField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '请输入 LTC 地址',
  );
  final amountField = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == '0.00',
  );
  await tester.enterText(addressField, address);
  await tester.enterText(amountField, amount);
  await unfocusAndPump(tester);
}

Future<void> fillXrpTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
  String? destinationTag,
}) async {
  await tester.enterText(
    find.byKey(const Key('xrp_transfer_address_field')),
    address,
  );
  await tester.enterText(
    find.byKey(const Key('xrp_transfer_amount_field')),
    amount,
  );
  if (destinationTag != null) {
    await tester.enterText(
      find.byKey(const Key('xrp_transfer_destination_tag_field')),
      destinationTag,
    );
  }
  await unfocusAndPump(tester);
}

Future<void> fillEvmTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  await tester.enterText(
    find.byKey(const Key('evm_transfer_address_field')),
    address,
  );
  await tester.enterText(
    find.byKey(const Key('evm_transfer_amount_field')),
    amount,
  );
  await unfocusAndPump(tester);
}

Future<void> fillTrxTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  final addressField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '请输入 TRON 地址',
  );
  final amountField = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == '0',
  );
  await tester.enterText(addressField, address);
  await tester.enterText(amountField, amount);
  await unfocusAndPump(tester);
}

Future<void> fillSolTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  final addressField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '请输入 Solana 地址',
  );
  final amountField = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == '0',
  );
  await tester.enterText(addressField, address);
  await tester.enterText(amountField, amount);
  await unfocusAndPump(tester);
}

Future<void> fillSuiTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  final addressField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == '请输入 Sui 地址',
  );
  final amountField = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == '0',
  );
  await tester.enterText(addressField, address);
  await tester.enterText(amountField, amount);
  await unfocusAndPump(tester);
}

Future<void> fillTonTransferForm(
  WidgetTester tester, {
  required String address,
  required String amount,
}) async {
  final addressField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == 'EQ... 或 0:...',
  );
  final amountField = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == '0',
  );
  await tester.enterText(addressField, address);
  await tester.enterText(amountField, amount);
  await unfocusAndPump(tester);
}

Future<void> submitAptTransfer(WidgetTester tester) async {
  await tapAndPump(tester, find.byKey(const Key('apt_transfer_submit_button')));
}

Finder _findVisibleMaterialButtonByText(String text) {
  final textFinder = find.text(text).hitTestable();
  return find.ancestor(
    of: textFinder,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is TextButton ||
          widget is ElevatedButton ||
          widget is OutlinedButton ||
          widget is FilledButton,
    ),
  );
}

Future<void> submitBtcTransfer(WidgetTester tester) async {
  await scrollToAndTap(tester, _findVisibleMaterialButtonByText('确定'));
}

Future<void> submitDogeTransfer(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('发送'));
}

Future<void> submitBchTransfer(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('发送'));
}

Future<void> submitLtcTransfer(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('发送'));
}

Future<void> submitXrpTransfer(WidgetTester tester) async {
  await tapAndPump(tester, find.byKey(const Key('xrp_transfer_submit_button')));
}

Future<void> submitTrxTransfer(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('确定'));
}

Future<void> submitSolTransfer(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('确定'));
}

Future<void> submitSuiTransfer(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('发送'));
}

Future<void> submitTonTransfer(WidgetTester tester) async {
  await scrollToAndTap(tester, find.text('发送 TON'));
}

Future<void> submitEvmTransfer(
  WidgetTester tester, {
  bool waitForConfirmDialog = false,
  Duration timeout = const Duration(seconds: 20),
  Duration retryStep = const Duration(seconds: 1),
}) async {
  await unfocusAndPump(tester);

  if (!waitForConfirmDialog) {
    await scrollToAndTap(
      tester,
      find.byKey(const Key('evm_transfer_submit_button')),
    );
    return;
  }

  final dialogFinder = find.byKey(
    const Key('evm_transfer_confirm_dialog_title'),
  );
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await scrollToAndTap(
      tester,
      find.byKey(const Key('evm_transfer_submit_button')),
    );
    if (dialogFinder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(retryStep);
  }

  throw TestFailure('Timed out waiting for EVM transfer confirm dialog');
}

Future<void> expectEvmTransferConfirmDialog(WidgetTester tester) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('evm_transfer_confirm_dialog_title')),
  );
  expect(
    find.byKey(const Key('evm_transfer_confirm_cancel_button')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('evm_transfer_confirm_confirm_button')),
    findsOneWidget,
  );
}

Future<void> confirmEvmTransferDialog(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('evm_transfer_confirm_confirm_button')),
  );
}

Future<void> expectPasswordVerificationDialogVisible(
  WidgetTester tester,
) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('password_verification_field')),
  );
  expect(
    find.byKey(const Key('password_verification_cancel_button')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('password_verification_confirm_button')),
    findsOneWidget,
  );
}

Future<void> cancelPasswordVerificationDialog(WidgetTester tester) async {
  await tapAndPump(
    tester,
    find.byKey(const Key('password_verification_cancel_button')),
  );
}

Future<void> waitForAptTransactionConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final confirmedFinder = find.text('交易已上链确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final failedFinder = find.text('交易执行失败');
    if (failedFinder.evaluate().isNotEmpty) {
      final vmStatusFinder = find.byKey(
        const Key('apt_transaction_status_vm_status'),
      );
      String? vmStatus;
      if (vmStatusFinder.evaluate().isNotEmpty) {
        vmStatus = tester.widget<Text>(vmStatusFinder).data;
      }
      throw TestFailure(
        vmStatus == null || vmStatus.isEmpty
            ? 'Apt testnet transaction failed'
            : 'Apt testnet transaction failed: $vmStatus',
      );
    }
  }

  throw TestFailure(
    'Timed out waiting for Apt testnet transaction confirmation',
  );
}

Future<void> waitForBtcTransactionBroadcastedOrConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final broadcastedFinder = find.text('交易已广播，等待链上确认');
    if (broadcastedFinder.evaluate().isNotEmpty) {
      return;
    }

    final confirmedFinder = find.text('交易已上链确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final failedFinder = find.text('交易执行失败');
    if (failedFinder.evaluate().isNotEmpty) {
      throw TestFailure('BTC testnet transaction failed');
    }
  }

  throw TestFailure(
    'Timed out waiting for BTC testnet transaction broadcast status',
  );
}

Future<void> waitForDogeTransactionBroadcastedOrConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final pendingFinder = find.text('待确认');
    if (pendingFinder.evaluate().isNotEmpty) {
      return;
    }

    final confirmedFinder = find.text('已确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final networkErrorFinder = find.textContaining('网络请求失败');
    if (networkErrorFinder.evaluate().isNotEmpty) {
      throw TestFailure('DOGE testnet transaction status lookup failed');
    }
  }

  throw TestFailure(
    'Timed out waiting for DOGE testnet transaction broadcast status',
  );
}

Future<void> waitForBchTransactionBroadcastedOrConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final pendingFinder = find.text('待确认');
    if (pendingFinder.evaluate().isNotEmpty) {
      return;
    }

    final confirmedFinder = find.text('已确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final networkErrorFinder = find.textContaining('网络请求失败');
    if (networkErrorFinder.evaluate().isNotEmpty) {
      throw TestFailure('BCH chipnet transaction status lookup failed');
    }
  }

  throw TestFailure(
    'Timed out waiting for BCH chipnet transaction broadcast status',
  );
}

Future<void> waitForLtcTransactionBroadcastedOrConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final pendingFinder = find.text('待确认');
    if (pendingFinder.evaluate().isNotEmpty) {
      return;
    }

    final confirmedFinder = find.text('已确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final networkErrorFinder = find.textContaining('网络请求失败');
    if (networkErrorFinder.evaluate().isNotEmpty) {
      throw TestFailure('LTC testnet transaction status lookup failed');
    }
  }

  throw TestFailure(
    'Timed out waiting for LTC testnet transaction broadcast status',
  );
}

Future<void> waitForXrpTransactionConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final confirmedFinder = find.text('交易已上链确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final failedFinder = find.text('交易执行失败');
    if (failedFinder.evaluate().isNotEmpty) {
      final statusMessageFinder = find.byKey(
        const Key('xrp_transaction_status_message'),
      );
      String? statusMessage;
      if (statusMessageFinder.evaluate().isNotEmpty) {
        statusMessage = tester.widget<Text>(statusMessageFinder).data;
      }
      throw TestFailure(
        statusMessage == null || statusMessage.isEmpty
            ? 'XRP testnet transaction failed'
            : 'XRP testnet transaction failed: $statusMessage',
      );
    }
  }

  throw TestFailure(
    'Timed out waiting for XRP testnet transaction confirmation',
  );
}

Future<void> waitForEvmTransactionConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final confirmedFinder = find.text('交易已上链确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final failedFinder = find.text('交易执行失败');
    if (failedFinder.evaluate().isNotEmpty) {
      final statusMessageFinder = find.byKey(
        const Key('evm_transaction_status_message'),
      );
      String? statusMessage;
      if (statusMessageFinder.evaluate().isNotEmpty) {
        statusMessage = tester.widget<Text>(statusMessageFinder).data;
      }
      throw TestFailure(
        statusMessage == null || statusMessage.isEmpty
            ? 'EVM transaction failed'
            : 'EVM transaction failed: $statusMessage',
      );
    }
  }

  throw TestFailure('Timed out waiting for EVM transaction confirmation');
}

Future<void> waitForTrxTransactionConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final confirmedFinder = find.text('交易已上链确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final failedFinder = find.text('交易执行失败');
    if (failedFinder.evaluate().isNotEmpty) {
      throw TestFailure('TRX transaction failed');
    }
  }

  throw TestFailure('Timed out waiting for TRX transaction confirmation');
}

Future<void> waitForSolTransactionConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final confirmedFinder = find.text('交易已上链确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final failedFinder = find.text('交易执行失败');
    if (failedFinder.evaluate().isNotEmpty) {
      throw TestFailure('SOL devnet transaction failed');
    }
  }

  throw TestFailure(
    'Timed out waiting for SOL devnet transaction confirmation',
  );
}

Future<void> waitForSuiTransactionConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final confirmedFinder = find.text('交易已上链确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final failedFinder = find.text('交易执行失败');
    if (failedFinder.evaluate().isNotEmpty) {
      throw TestFailure('SUI testnet transaction failed');
    }
  }

  throw TestFailure(
    'Timed out waiting for SUI testnet transaction confirmation',
  );
}

Future<void> waitForTonTransactionConfirmed(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 2),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);

    final confirmedFinder = find.text('交易已上链确认');
    if (confirmedFinder.evaluate().isNotEmpty) {
      return;
    }

    final failedFinder = find.text('交易已上链，但执行失败');
    if (failedFinder.evaluate().isNotEmpty) {
      throw TestFailure('TON testnet transaction failed');
    }
  }

  throw TestFailure(
    'Timed out waiting for TON testnet transaction confirmation',
  );
}

Future<void> unlockPasswordPrompt(
  WidgetTester tester, {
  String password = 'Passw0rd!',
}) async {
  await pumpUntilVisible(
    tester,
    find.byKey(const Key('password_verification_field')),
  );
  await tester.enterText(
    find.byKey(const Key('password_verification_field')),
    password,
  );
  await tapAndPump(
    tester,
    find.byKey(const Key('password_verification_confirm_button')),
  );
}

Future<void> addHdWalletByChainId(
  WidgetTester tester, {
  required String chainId,
  String password = 'Passw0rd!',
}) async {
  final chainFinder = find.byKey(Key('hd_wallet_add_chain_$chainId'));
  await tester.scrollUntilVisible(
    chainFinder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tapAndPump(tester, chainFinder);
  await tapAndPump(
    tester,
    find.byKey(Key('hd_wallet_list_add_subwallet_$chainId')),
    settle: const Duration(seconds: 1),
  );

  final continueButtonFinder =
      find.byKey(const Key('sensitive_action_confirm_continue_button'));
  final passwordDialogFinder = find.byKey(
    const Key('password_verification_field'),
  );
  final walletHomeFinder = find.byKey(const Key('wallet_home_selector_button'));
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    // Dismiss the SensitiveOperationGuard confirmation dialog if present.
    if (continueButtonFinder.evaluate().isNotEmpty) {
      await tapAndPump(tester, continueButtonFinder);
      continue;
    }
    if (passwordDialogFinder.evaluate().isNotEmpty) {
      await unlockPasswordPrompt(tester, password: password);
      return;
    }
    if (walletHomeFinder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  throw TestFailure(
    'Timed out while adding HD wallet for chainId "$chainId": '
    'neither the password verification dialog nor the wallet home appeared.',
  );
}

Future<void> captureToastMessages(List<String> toastMessages) async {
  toastMessages.clear();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(kToastChannel, (call) async {
        final arguments = call.arguments;
        if (arguments is Map) {
          final msg = arguments['msg'];
          if (msg is String) {
            toastMessages.add(msg);
          }
        }
        return true;
      });
}

Future<void> stopCapturingToastMessages() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(kToastChannel, null);
}

void expectLatestToastMessage(List<String> toastMessages, String message) {
  expect(toastMessages, isNotEmpty);
  expect(toastMessages.last, message);
}

Future<void> waitForToastMessage(
  WidgetTester tester,
  List<String> toastMessages, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (toastMessages.isNotEmpty) {
      return;
    }
    await tester.pump(step);
  }

  throw TestFailure('Timed out waiting for toast message');
}

Future<void> waitForToastMessageValue(
  WidgetTester tester,
  List<String> toastMessages, {
  required String message,
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (toastMessages.contains(message)) {
      return;
    }
    await tester.pump(step);
  }

  throw TestFailure(
    'Timed out waiting for toast message "$message". '
    'Observed: $toastMessages',
  );
}

Future<void> waitForToastMessageContaining(
  WidgetTester tester,
  List<String> toastMessages, {
  required String message,
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (toastMessages.any((toast) => toast.contains(message))) {
      return;
    }
    await tester.pump(step);
  }

  throw TestFailure(
    'Timed out waiting for toast message containing "$message". '
    'Observed: $toastMessages',
  );
}

Future<void> captureExternalLaunchUrls(List<String> launchedUrls) async {
  launchedUrls.clear();
  if (!supportsExternalLaunchUrlCapture) {
    return;
  }
  final channel = BasicMessageChannel<Object?>(
    kUrlLauncherIosLaunchChannelName,
    kUrlLauncherIosPigeonCodec,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(channel, (message) async {
        final arguments = message as List<Object?>?;
        final url = arguments != null && arguments.isNotEmpty
            ? arguments.first
            : null;
        if (url is String) {
          launchedUrls.add(url);
        }
        return <Object?>[_UrlLauncherIosLaunchResult.success];
      });
}

Future<void> stopCapturingExternalLaunchUrls() async {
  if (!supportsExternalLaunchUrlCapture) {
    return;
  }
  final channel = BasicMessageChannel<Object?>(
    kUrlLauncherIosLaunchChannelName,
    kUrlLauncherIosPigeonCodec,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(channel, null);
}

void expectLatestExternalLaunchUrl(List<String> launchedUrls, String url) {
  if (!supportsExternalLaunchUrlCapture) {
    return;
  }
  expect(launchedUrls, isNotEmpty);
  expect(launchedUrls.last, url);
}
