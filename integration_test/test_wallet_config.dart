import 'dart:convert';
import 'dart:io';

const String kIntegrationTestWalletConfigEnvVar =
    'ZERO_ITEST_WALLET_CONFIG_B64';
const String kTrxNetworkNile = 'nile';
const String kTrxNetworkShasta = 'shasta';
const String kTrxNetworkMainnet = 'mainnet';

class IntegrationTestWalletConfig {
  const IntegrationTestWalletConfig({
    required this.fundedAptTestnetMnemonic,
    required this.fundedAptTestnetAddress,
    required this.aptTestnetTransferRecipientAddress,
    this.fundedEthSepoliaMnemonic = '',
    this.fundedEthSepoliaAddress = '',
    this.ethSepoliaTransferRecipientAddress = '',
    this.ethSepoliaTransferAmount = '0.0001',
    this.fundedXrpTestnetMnemonic = '',
    this.fundedXrpTestnetAddress = '',
    this.xrpTestnetTransferRecipientAddress = '',
    this.xrpTestnetTransferAmount = '1',
    this.xrpTestnetTransferDestinationTag = '',
    this.fundedSolDevnetMnemonic = '',
    this.fundedSolDevnetAddress = '',
    this.solDevnetTransferRecipientAddress = '',
    this.solDevnetTransferAmount = '0.01',
    this.fundedTrxMnemonic = '',
    this.fundedTrxAddress = '',
    this.trxTransferNetwork = kTrxNetworkNile,
    this.trxNileTransferRecipientAddress = '',
    this.trxNileTransferAmount = '1',
    this.trxShastaTransferRecipientAddress = '',
    this.trxShastaTransferAmount = '1',
    this.trxMainnetTransferRecipientAddress = '',
    this.trxMainnetTransferAmount = '1',
  });

  final String fundedAptTestnetMnemonic;
  final String fundedAptTestnetAddress;
  final String aptTestnetTransferRecipientAddress;
  final String fundedEthSepoliaMnemonic;
  final String fundedEthSepoliaAddress;
  final String ethSepoliaTransferRecipientAddress;
  final String ethSepoliaTransferAmount;
  final String fundedXrpTestnetMnemonic;
  final String fundedXrpTestnetAddress;
  final String xrpTestnetTransferRecipientAddress;
  final String xrpTestnetTransferAmount;
  final String xrpTestnetTransferDestinationTag;
  final String fundedSolDevnetMnemonic;
  final String fundedSolDevnetAddress;
  final String solDevnetTransferRecipientAddress;
  final String solDevnetTransferAmount;
  final String fundedTrxMnemonic;
  final String fundedTrxAddress;
  final String trxTransferNetwork;
  final String trxNileTransferRecipientAddress;
  final String trxNileTransferAmount;
  final String trxShastaTransferRecipientAddress;
  final String trxShastaTransferAmount;
  final String trxMainnetTransferRecipientAddress;
  final String trxMainnetTransferAmount;

  factory IntegrationTestWalletConfig.fromJson(Map<String, dynamic> json) {
    final ethAmount = json['ethSepoliaTransferAmount']?.toString().trim() ?? '';
    final xrpAmount = json['xrpTestnetTransferAmount']?.toString().trim() ?? '';
    final solAmount = json['solDevnetTransferAmount']?.toString().trim() ?? '';
    final trxNetwork =
        json['trxTransferNetwork']?.toString().trim().toLowerCase() ??
        kTrxNetworkNile;
    final trxNileAmount =
        json['trxNileTransferAmount']?.toString().trim() ?? '';
    final trxShastaAmount =
        json['trxShastaTransferAmount']?.toString().trim() ?? '';
    final trxAmount = json['trxMainnetTransferAmount']?.toString().trim() ?? '';
    final trxDefaultRecipient =
        json['trxMainnetTransferRecipientAddress']?.toString().trim() ?? '';
    return IntegrationTestWalletConfig(
      fundedAptTestnetMnemonic:
          json['fundedAptTestnetMnemonic']?.toString().trim() ?? '',
      fundedAptTestnetAddress:
          json['fundedAptTestnetAddress']?.toString().trim() ?? '',
      aptTestnetTransferRecipientAddress:
          json['aptTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      fundedEthSepoliaMnemonic:
          json['fundedEthSepoliaMnemonic']?.toString().trim() ?? '',
      fundedEthSepoliaAddress:
          json['fundedEthSepoliaAddress']?.toString().trim() ?? '',
      ethSepoliaTransferRecipientAddress:
          json['ethSepoliaTransferRecipientAddress']?.toString().trim() ?? '',
      ethSepoliaTransferAmount: ethAmount.isEmpty ? '0.0001' : ethAmount,
      fundedXrpTestnetMnemonic:
          json['fundedXrpTestnetMnemonic']?.toString().trim() ?? '',
      fundedXrpTestnetAddress:
          json['fundedXrpTestnetAddress']?.toString().trim() ?? '',
      xrpTestnetTransferRecipientAddress:
          json['xrpTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      xrpTestnetTransferAmount: xrpAmount.isEmpty ? '1' : xrpAmount,
      xrpTestnetTransferDestinationTag:
          json['xrpTestnetTransferDestinationTag']?.toString().trim() ?? '',
      fundedSolDevnetMnemonic:
          json['fundedSolDevnetMnemonic']?.toString().trim() ?? '',
      fundedSolDevnetAddress:
          json['fundedSolDevnetAddress']?.toString().trim() ?? '',
      solDevnetTransferRecipientAddress:
          json['solDevnetTransferRecipientAddress']?.toString().trim() ?? '',
      solDevnetTransferAmount: solAmount.isEmpty ? '0.01' : solAmount,
      fundedTrxMnemonic:
          json['fundedTrxMnemonic']?.toString().trim() ??
          json['fundedTrxMainnetMnemonic']?.toString().trim() ??
          '',
      fundedTrxAddress:
          json['fundedTrxAddress']?.toString().trim() ??
          json['fundedTrxMainnetAddress']?.toString().trim() ??
          '',
      trxTransferNetwork: switch (trxNetwork) {
        kTrxNetworkNile ||
        kTrxNetworkShasta ||
        kTrxNetworkMainnet => trxNetwork,
        _ => kTrxNetworkNile,
      },
      trxNileTransferRecipientAddress:
          json['trxNileTransferRecipientAddress']?.toString().trim() ??
          trxDefaultRecipient,
      trxNileTransferAmount: trxNileAmount.isEmpty ? '1' : trxNileAmount,
      trxShastaTransferRecipientAddress:
          json['trxShastaTransferRecipientAddress']?.toString().trim() ??
          trxDefaultRecipient,
      trxShastaTransferAmount: trxShastaAmount.isEmpty ? '1' : trxShastaAmount,
      trxMainnetTransferRecipientAddress: trxDefaultRecipient,
      trxMainnetTransferAmount: trxAmount.isEmpty ? '1' : trxAmount,
    );
  }

  bool get hasFundedAptTestnetWallet =>
      fundedAptTestnetMnemonic.isNotEmpty &&
      fundedAptTestnetAddress.isNotEmpty &&
      aptTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedEthSepoliaWallet =>
      fundedEthSepoliaMnemonic.isNotEmpty &&
      fundedEthSepoliaAddress.isNotEmpty &&
      ethSepoliaTransferRecipientAddress.isNotEmpty;

  bool get hasFundedXrpTestnetWallet =>
      fundedXrpTestnetMnemonic.isNotEmpty &&
      fundedXrpTestnetAddress.isNotEmpty &&
      xrpTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedSolDevnetWallet =>
      fundedSolDevnetMnemonic.isNotEmpty &&
      fundedSolDevnetAddress.isNotEmpty &&
      solDevnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedTrxWalletForTransferNetwork =>
      fundedTrxMnemonic.isNotEmpty &&
      fundedTrxAddress.isNotEmpty &&
      trxTransferRecipientAddress.isNotEmpty;

  String get trxTransferRecipientAddress => switch (trxTransferNetwork) {
    kTrxNetworkNile => trxNileTransferRecipientAddress,
    kTrxNetworkShasta => trxShastaTransferRecipientAddress,
    kTrxNetworkMainnet => trxMainnetTransferRecipientAddress,
    _ => trxNileTransferRecipientAddress,
  };

  String get trxTransferAmount => switch (trxTransferNetwork) {
    kTrxNetworkNile => trxNileTransferAmount,
    kTrxNetworkShasta => trxShastaTransferAmount,
    kTrxNetworkMainnet => trxMainnetTransferAmount,
    _ => trxNileTransferAmount,
  };

  bool get hasAnyFundedWallet =>
      hasFundedAptTestnetWallet ||
      hasFundedEthSepoliaWallet ||
      hasFundedXrpTestnetWallet ||
      hasFundedSolDevnetWallet ||
      hasFundedTrxWalletForTransferNetwork;

  String? get xrpTestnetTransferDestinationTagOrNull {
    return xrpTestnetTransferDestinationTag.isEmpty
        ? null
        : xrpTestnetTransferDestinationTag;
  }
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
