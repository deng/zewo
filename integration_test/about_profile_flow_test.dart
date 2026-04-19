import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('opens about page from profile page', (tester) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'ABOUT');
    await expectWalletHome(tester, walletName: 'ABOUT');

    await tapAndPump(tester, find.byKey(const Key('bottom_nav_profile')));
    await pumpUntilVisible(tester, find.byKey(const Key('profile_page_title')));
    await scrollFinderIntoView(
      tester,
      find.byKey(const Key('profile_about_tile')),
    );
    await tapAndPump(tester, find.byKey(const Key('profile_about_tile')));

    await pumpUntilVisible(tester, find.byKey(const Key('about_page_title')));
    await pumpUntilVisible(tester, find.byKey(const Key('about_app_name')));
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('about_issue_tracker_tile')),
    );
  });
}
