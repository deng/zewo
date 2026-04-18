import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('manages address book from profile page', (tester) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'ADDR BOOK');
    await expectWalletHome(tester, walletName: 'ADDR BOOK');

    await tapAndPump(tester, find.byKey(const Key('bottom_nav_profile')));
    await pumpUntilVisible(tester, find.byKey(const Key('profile_page_title')));
    expect(find.byKey(const Key('profile_page_title')), findsOneWidget);
    expect(find.byKey(const Key('profile_address_book_tile')), findsOneWidget);

    await tapAndPump(
      tester,
      find.byKey(const Key('profile_address_book_tile')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('address_book_page_title')),
    );

    await expectTextVisible(tester, '还没有联系人');
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('address_book_empty_add_button')),
    );
    await tapAndPump(
      tester,
      find.byKey(const Key('address_book_empty_add_button')),
    );

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('address_book_edit_name_field')),
    );
    await tester.enterText(
      find.byKey(const Key('address_book_edit_name_field')),
      'Alice',
    );
    await tester.enterText(
      find.byKey(const Key('address_book_edit_address_field')),
      '0x1111111111111111111111111111111111111111',
    );
    await tester.enterText(
      find.byKey(const Key('address_book_edit_note_field')),
      'Friend',
    );
    await unfocusAndPump(tester);

    await scrollToAndTap(
      tester,
      find.byKey(const Key('address_book_edit_save_button')),
    );

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('address_book_page_title')),
    );
    await expectTextVisible(tester, 'Alice');
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.text('Friend'), findsOneWidget);
  });
}
