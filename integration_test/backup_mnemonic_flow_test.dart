import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_wallet/wallet.dart';

import 'test_helpers.dart';

void main() {
  configureIntegrationTest();

  testWidgets('creates wallet then opens backup mnemonic page from hd manage', (
    tester,
  ) async {
    await launchTestApp();

    await createWalletFromHome(tester, walletName: 'Backup One');
    await expectWalletHome(tester, walletName: 'Backup One');

    await openWalletDetailFromHome(tester);
    await expectTextVisible(tester, '钱包详情');

    await openHdManageFromWalletDetail(tester);
    await pumpUntilVisible(
      tester,
      find.byKey(const Key('backup_mnemonic_menu_item')),
    );

    await openBackupMnemonicFromHdManage(tester);
    await unlockBackupMnemonic(tester);
    await expectBackupMnemonicPage(tester);

    final currentWallet = WalletProvider.getInstance()?.currentWallet;
    expect(currentWallet?.mnemonicId, isNotNull);

    final mnemonic = await WalletService.getMnemonic(
      currentWallet!.mnemonicId!,
      'Passw0rd!',
    );
    await completeBackupMnemonicVerification(
      tester,
      mnemonicWords: mnemonic.split(' '),
    );

    await expectTextVisible(tester, '已备份');
  });
}
