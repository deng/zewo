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

const IntegrationTestWalletConfig
kDefaultIntegrationTestWalletConfig = IntegrationTestWalletConfig(
  fundedAptTestnetMnemonic:
      'material ripple excuse loop below route congress october theme tiny arrive matter',
  fundedAptTestnetAddress:
      '0x2012f22e2e1780a0e78208f40cfb3cf6b84f6cb7f49f2fa053d97a056e630642',
  aptTestnetTransferRecipientAddress:
      '0x1111111111111111111111111111111111111111111111111111111111111111',
);

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
    return kDefaultIntegrationTestWalletConfig;
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
  return config.hasFundedAptTestnetWallet
      ? config
      : kDefaultIntegrationTestWalletConfig;
}
