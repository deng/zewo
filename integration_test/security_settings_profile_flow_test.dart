import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('updates security settings and changes wallet password', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'SECURITY');
    await expectWalletHome(tester, walletName: 'SECURITY');

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet, isNotNull);
    expect(currentWallet!.mnemonicId, isNotNull);

    await tapAndPump(tester, find.byKey(const Key('bottom_nav_profile')));
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('profile_security_settings_tile')),
    );
    await tapAndPump(
      tester,
      find.byKey(const Key('profile_security_settings_tile')),
    );

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('security_settings_page_title')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('security_settings_biometric_switch')),
    );

    await tester.tap(
      find.byKey(const Key('security_settings_biometric_switch')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('security_settings_auto_lock_dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(const Key('security_settings_auto_lock_option_minute15_label'))
          .last,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('security_settings_screenshot_switch')),
    );
    await tester.pumpAndSettle();

    await tapAndPump(
      tester,
      find.byKey(const Key('security_settings_change_password_tile')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('sensitive_action_confirm_title')),
    );
    await tapAndPump(
      tester,
      find.byKey(const Key('sensitive_action_confirm_cancel_button')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('security_settings_page_title')),
    );

    await tester.tap(
      find.byKey(const Key('security_settings_sensitive_confirm_switch')),
    );
    await tester.pumpAndSettle();

    await tapAndPump(
      tester,
      find.byKey(const Key('security_settings_change_password_tile')),
    );
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('change_wallet_password_old_field')),
    );
    await tester.enterText(
      find.byKey(const Key('change_wallet_password_old_field')),
      'Passw0rd!',
    );
    await tester.enterText(
      find.byKey(const Key('change_wallet_password_new_field')),
      'NewPassw0rd!',
    );
    await tester.enterText(
      find.byKey(const Key('change_wallet_password_confirm_field')),
      'NewPassw0rd!',
    );
    await unfocusAndPump(tester);
    await tapAndPump(
      tester,
      find.byKey(const Key('change_wallet_password_submit_button')),
      settle: const Duration(seconds: 1),
    );

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('security_settings_page_title')),
    );

    final restoredSecurityController = SecuritySettingsController();
    await restoredSecurityController.initialize();
    expect(restoredSecurityController.biometricUnlockEnabled, isTrue);
    expect(
      restoredSecurityController.autoLockDuration,
      AppAutoLockDuration.minute15,
    );
    expect(restoredSecurityController.screenshotProtectionEnabled, isTrue);
    expect(
      restoredSecurityController.sensitiveOperationConfirmationEnabled,
      isFalse,
    );

    await expectLater(
      WalletService.getMnemonic(currentWallet.mnemonicId!, 'Passw0rd!'),
      throwsA(isA<WalletAuthenticationException>()),
    );
    final mnemonic = await WalletService.getMnemonic(
      currentWallet.mnemonicId!,
      'NewPassw0rd!',
    );
    expect(mnemonic, isNotEmpty);
  });
}
