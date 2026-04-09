import 'dart:convert';
import 'dart:io';

class IntegrationTestWalletConfig {
  const IntegrationTestWalletConfig({
    required this.fundedAptTestnetMnemonic,
    required this.fundedAptTestnetAddress,
    required this.aptTestnetTransferRecipientAddress,
  });

  final String fundedAptTestnetMnemonic;
  final String fundedAptTestnetAddress;
  final String aptTestnetTransferRecipientAddress;

  factory IntegrationTestWalletConfig.fromJson(Map<String, dynamic> json) {
    return IntegrationTestWalletConfig(
      fundedAptTestnetMnemonic:
          json['fundedAptTestnetMnemonic']?.toString().trim() ?? '',
      fundedAptTestnetAddress:
          json['fundedAptTestnetAddress']?.toString().trim() ?? '',
      aptTestnetTransferRecipientAddress:
          json['aptTestnetTransferRecipientAddress']?.toString().trim() ?? '',
    );
  }

  bool get hasFundedAptTestnetWallet =>
      fundedAptTestnetMnemonic.isNotEmpty &&
      fundedAptTestnetAddress.isNotEmpty &&
      aptTestnetTransferRecipientAddress.isNotEmpty;
}

const List<String> kIntegrationTestWalletConfigPaths = <String>[
  'integration_test/.test_wallet_config.json',
  'zero/integration_test/.test_wallet_config.json',
];

IntegrationTestWalletConfig? loadIntegrationTestWalletConfig() {
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
  if (content.isEmpty) {
    return null;
  }

  final decoded = jsonDecode(content);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('集成测试钱包配置格式无效');
  }

  final config = IntegrationTestWalletConfig.fromJson(decoded);
  return config.hasFundedAptTestnetWallet ? config : null;
}
