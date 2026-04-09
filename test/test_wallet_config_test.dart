import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/test_wallet_config.dart';

void main() {
  late String originalCurrentDirectory;
  late Directory tempDir;

  setUp(() async {
    originalCurrentDirectory = Directory.current.path;
    tempDir = await Directory.systemTemp.createTemp('zero_test_wallet_config_');
    Directory.current = tempDir.path;
  });

  tearDown(() async {
    Directory.current = originalCurrentDirectory;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns null when no local test wallet config exists', () {
    expect(loadIntegrationTestWalletConfig(), isNull);
  });

  test('returns null when local test wallet config is incomplete', () async {
    final integrationTestDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}integration_test',
    );
    await integrationTestDir.create(recursive: true);
    final configFile = File(
      '${integrationTestDir.path}${Platform.pathSeparator}.test_wallet_config.json',
    );
    await configFile.writeAsString('{"fundedAptTestnetMnemonic":"only"}');

    expect(loadIntegrationTestWalletConfig(), isNull);
  });

  test('returns null when local test wallet config json is malformed', () async {
    final integrationTestDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}integration_test',
    );
    await integrationTestDir.create(recursive: true);
    final configFile = File(
      '${integrationTestDir.path}${Platform.pathSeparator}.test_wallet_config.json',
    );
    await configFile.writeAsString('{not-json');

    expect(loadIntegrationTestWalletConfig(), isNull);
  });

  test('loads funded wallet config from local json file', () async {
    final integrationTestDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}integration_test',
    );
    await integrationTestDir.create(recursive: true);
    final configFile = File(
      '${integrationTestDir.path}${Platform.pathSeparator}.test_wallet_config.json',
    );
    await configFile.writeAsString('''
{
  "fundedAptTestnetMnemonic": "mnemonic words",
  "fundedAptTestnetAddress": "0xabc",
  "aptTestnetTransferRecipientAddress": "0xdef"
}
''');

    final config = loadIntegrationTestWalletConfig();

    expect(config, isNotNull);
    expect(config!.hasFundedAptTestnetWallet, isTrue);
    expect(config.fundedAptTestnetMnemonic, 'mnemonic words');
    expect(config.fundedAptTestnetAddress, '0xabc');
    expect(config.aptTestnetTransferRecipientAddress, '0xdef');
  });
}
