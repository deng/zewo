import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('updates usage settings from profile page', (tester) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'SETTINGS');
    await expectWalletHome(tester, walletName: 'SETTINGS');

    await tapAndPump(tester, find.byKey(const Key('bottom_nav_profile')));
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('profile_usage_settings_tile')),
    );
    await tapAndPump(
      tester,
      find.byKey(const Key('profile_usage_settings_tile')),
    );

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('usage_settings_page_title')),
    );

    await tester.tap(find.byKey(const Key('usage_settings_language_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(const Key('usage_settings_language_option_english_label'))
          .last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('usage_settings_theme_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('usage_settings_theme_option_light_label')).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('usage_settings_developer_switch')));
    await tester.pumpAndSettle();

    final languageValueFinder = find.byKey(
      const Key('usage_settings_language_value'),
    );
    final themeValueFinder = find.byKey(
      const Key('usage_settings_theme_value'),
    );
    await pumpUntilVisible(tester, languageValueFinder);
    await pumpUntilVisible(tester, themeValueFinder);
    expect(tester.widget<Text>(languageValueFinder).data, 'English');
    expect(tester.widget<Text>(themeValueFinder).data, 'Light');

    final developerSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('usage_settings_developer_switch')),
    );
    expect(developerSwitch.value, isTrue);

    final restoredController = UsageSettingsController();
    await restoredController.initialize();
    expect(restoredController.language, AppLanguage.english);
    expect(restoredController.themePreference, AppThemePreference.light);
    expect(restoredController.developerMode, isTrue);
  });
}
