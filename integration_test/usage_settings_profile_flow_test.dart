import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('usage_settings_theme_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('浅色').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('usage_settings_developer_switch')));
    await tester.pumpAndSettle();

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('usage_settings_language_value')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('usage_settings_theme_value')),
    );
    expect(find.text('English'), findsWidgets);
    expect(find.text('浅色'), findsWidgets);

    final developerSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('usage_settings_developer_switch')),
    );
    expect(developerSwitch.value, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tapAndPump(
      tester,
      find.byKey(const Key('profile_usage_settings_tile')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('usage_settings_page_title')),
    );
    expect(find.text('English'), findsWidgets);
    expect(find.text('浅色'), findsWidgets);
    final persistedSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('usage_settings_developer_switch')),
    );
    expect(persistedSwitch.value, isTrue);
  });
}
