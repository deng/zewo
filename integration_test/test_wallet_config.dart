import 'dart:convert';
import 'dart:io';

const String kIntegrationTestWalletConfigEnvVar =
    'ZERO_ITEST_WALLET_CONFIG_B64';

class IntegrationTestWalletConfig {
  const IntegrationTestWalletConfig({
    required this.fundedAptTestnetMnemonic,
    required this.fundedAptTestnetAddress,
    required this.aptTestnetTransferRecipientAddress,
    this.fundedXrpTestnetMnemonic = '',
    this.fundedXrpTestnetAddress = '',
    this.xrpTestnetTransferRecipientAddress = '',
    this.xrpTestnetTransferAmount = '1',
    this.xrpTestnetTransferDestinationTag = '',
  });

  final String fundedAptTestnetMnemonic;
  final String fundedAptTestnetAddress;
  final String aptTestnetTransferRecipientAddress;
  final String fundedXrpTestnetMnemonic;
  final String fundedXrpTestnetAddress;
  final String xrpTestnetTransferRecipientAddress;
  final String xrpTestnetTransferAmount;
  final String xrpTestnetTransferDestinationTag;

  factory IntegrationTestWalletConfig.fromJson(Map<String, dynamic> json) {
    final xrpAmount = json['xrpTestnetTransferAmount']?.toString().trim() ?? '';
    return IntegrationTestWalletConfig(
      fundedAptTestnetMnemonic:
          json['fundedAptTestnetMnemonic']?.toString().trim() ?? '',
      fundedAptTestnetAddress:
          json['fundedAptTestnetAddress']?.toString().trim() ?? '',
      aptTestnetTransferRecipientAddress:
          json['aptTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      fundedXrpTestnetMnemonic:
          json['fundedXrpTestnetMnemonic']?.toString().trim() ?? '',
      fundedXrpTestnetAddress:
          json['fundedXrpTestnetAddress']?.toString().trim() ?? '',
      xrpTestnetTransferRecipientAddress:
          json['xrpTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      xrpTestnetTransferAmount: xrpAmount.isEmpty ? '1' : xrpAmount,
      xrpTestnetTransferDestinationTag:
          json['xrpTestnetTransferDestinationTag']?.toString().trim() ?? '',
    );
  }

  bool get hasFundedAptTestnetWallet =>
      fundedAptTestnetMnemonic.isNotEmpty &&
      fundedAptTestnetAddress.isNotEmpty &&
      aptTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedXrpTestnetWallet =>
      fundedXrpTestnetMnemonic.isNotEmpty &&
      fundedXrpTestnetAddress.isNotEmpty &&
      xrpTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasAnyFundedWallet =>
      hasFundedAptTestnetWallet || hasFundedXrpTestnetWallet;

  String? get xrpTestnetTransferDestinationTagOrNull =>
      xrpTestnetTransferDestinationTag.isEmpty
      ? null
      : xrpTestnetTransferDestinationTag;
}

const List<String> kIntegrationTestWalletConfigPaths = <String>[
  'integration_test/.test_wallet_config.json',
  'zero/integration_test/.test_wallet_config.json',
];

IntegrationTestWalletConfig? loadIntegrationTestWalletConfig() {
  final environmentContent = _loadConfigContentFromEnvironment();
  if (environmentContent != null) {
    final parsed = _parseConfigContent(
      environmentContent,
      sourceLabel: 'dart-define $kIntegrationTestWalletConfigEnvVar',
    );
    if (parsed != null) {
      return parsed;
    }
  }

  File? configFile;
  for (final candidatePath in kIntegrationTestWalletConfigPaths) {
    final candidate = File(candidatePath);
    if (candidate.existsSync()) {
      configFile = candidate;
      break;
    }
  }

  if (configFile == null) {
    return null;
  }

  final content = configFile.readAsStringSync().trim();
  return _parseConfigContent(content, sourceLabel: configFile.path);
}

String? _loadConfigContentFromEnvironment() {
  const encoded = String.fromEnvironment(kIntegrationTestWalletConfigEnvVar);
  if (encoded.isEmpty) {
    return null;
  }
  try {
    return utf8.decode(base64Decode(encoded)).trim();
  } on FormatException catch (e) {
    stderr.writeln(
      'Skipping funded integration tests: invalid wallet config in '
      'dart-define $kIntegrationTestWalletConfigEnvVar: $e',
    );
    return null;
  }
}

IntegrationTestWalletConfig? _parseConfigContent(
  String content, {
  required String sourceLabel,
}) {
  if (content.isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('集成测试钱包配置格式无效');
    }

    final config = IntegrationTestWalletConfig.fromJson(decoded);
    return config.hasAnyFundedWallet ? config : null;
  } on FormatException catch (e) {
    stderr.writeln(
      'Skipping funded integration tests: invalid wallet config in '
      '$sourceLabel: $e',
    );
    return null;
  }
}
