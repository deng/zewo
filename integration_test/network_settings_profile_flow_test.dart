import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('opens network settings from profile page', (tester) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'NETWORK');
    await expectWalletHome(tester, walletName: 'NETWORK');

    await tapAndPump(tester, find.byKey(const Key('bottom_nav_profile')));
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('profile_network_settings_tile')),
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('profile_network_settings_tile')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('network_settings_page_title')),
    );

    await tapAndPump(
      tester,
      find.byKey(const Key('network_settings_manage_evm_tile')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('manage_custom_evm_networks_title')),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tapAndPump(
      tester,
      find.byKey(const Key('network_settings_manage_tron_tile')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('manage_custom_tron_networks_title')),
    );
  });
}
