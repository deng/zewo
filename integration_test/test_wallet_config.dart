import 'dart:convert';
import 'dart:io';

const String kIntegrationTestWalletConfigEnvVar =
    'ZERO_ITEST_WALLET_CONFIG_B64';
const String kTrxNetworkNile = 'nile';
const String kTrxNetworkShasta = 'shasta';
const String kTrxNetworkMainnet = 'mainnet';

class IntegrationTestWalletConfig {
  const IntegrationTestWalletConfig({
    this.fundedBtcTestnetMnemonic = '',
    this.fundedBtcTestnetAddress = '',
    this.btcTestnetTransferRecipientAddress = '',
    this.btcTestnetTransferAmount = '0.0001',
    this.fundedDogeTestnetMnemonic = '',
    this.fundedDogeTestnetAddress = '',
    this.dogeTestnetTransferRecipientAddress = '',
    this.dogeTestnetTransferAmount = '1',
    this.fundedBchTestnetMnemonic = '',
    this.fundedBchTestnetAddress = '',
    this.bchTestnetTransferRecipientAddress = '',
    this.bchTestnetTransferAmount = '0.001',
    this.fundedLtcTestnetMnemonic = '',
    this.fundedLtcTestnetAddress = '',
    this.ltcTestnetTransferRecipientAddress = '',
    this.ltcTestnetTransferAmount = '0.001',
    required this.fundedAptTestnetMnemonic,
    required this.fundedAptTestnetAddress,
    required this.aptTestnetTransferRecipientAddress,
    this.fundedEthSepoliaMnemonic = '',
    this.fundedEthSepoliaAddress = '',
    this.ethSepoliaTransferRecipientAddress = '',
    this.ethSepoliaTransferAmount = '0.0001',
    this.fundedBscTestnetMnemonic = '',
    this.fundedBscTestnetAddress = '',
    this.bscTestnetTransferRecipientAddress = '',
    this.bscTestnetTransferAmount = '0.001',
    this.fundedPolygonTestnetMnemonic = '',
    this.fundedPolygonTestnetAddress = '',
    this.polygonTestnetTransferRecipientAddress = '',
    this.polygonTestnetTransferAmount = '0.001',
    this.fundedBaseTestnetMnemonic = '',
    this.fundedBaseTestnetAddress = '',
    this.baseTestnetTransferRecipientAddress = '',
    this.baseTestnetTransferAmount = '0.0001',
    this.fundedArbitrumTestnetMnemonic = '',
    this.fundedArbitrumTestnetAddress = '',
    this.arbitrumTestnetTransferRecipientAddress = '',
    this.arbitrumTestnetTransferAmount = '0.0001',
    this.fundedOptimismTestnetMnemonic = '',
    this.fundedOptimismTestnetAddress = '',
    this.optimismTestnetTransferRecipientAddress = '',
    this.optimismTestnetTransferAmount = '0.0001',
    this.fundedXrpTestnetMnemonic = '',
    this.fundedXrpTestnetAddress = '',
    this.xrpTestnetTransferRecipientAddress = '',
    this.xrpTestnetTransferAmount = '1',
    this.xrpTestnetTransferDestinationTag = '',
    this.fundedSolDevnetMnemonic = '',
    this.fundedSolDevnetAddress = '',
    this.solDevnetTransferRecipientAddress = '',
    this.solDevnetTransferAmount = '0.01',
    this.fundedSuiTestnetMnemonic = '',
    this.fundedSuiTestnetAddress = '',
    this.suiTestnetTransferRecipientAddress = '',
    this.suiTestnetTransferAmount = '0.01',
    this.fundedTonTestnetMnemonic = '',
    this.fundedTonTestnetAddress = '',
    this.tonTestnetTransferRecipientAddress = '',
    this.tonTestnetTransferAmount = '0.05',
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

  final String fundedBtcTestnetMnemonic;
  final String fundedBtcTestnetAddress;
  final String btcTestnetTransferRecipientAddress;
  final String btcTestnetTransferAmount;
  final String fundedDogeTestnetMnemonic;
  final String fundedDogeTestnetAddress;
  final String dogeTestnetTransferRecipientAddress;
  final String dogeTestnetTransferAmount;
  final String fundedBchTestnetMnemonic;
  final String fundedBchTestnetAddress;
  final String bchTestnetTransferRecipientAddress;
  final String bchTestnetTransferAmount;
  final String fundedLtcTestnetMnemonic;
  final String fundedLtcTestnetAddress;
  final String ltcTestnetTransferRecipientAddress;
  final String ltcTestnetTransferAmount;
  final String fundedAptTestnetMnemonic;
  final String fundedAptTestnetAddress;
  final String aptTestnetTransferRecipientAddress;
  final String fundedEthSepoliaMnemonic;
  final String fundedEthSepoliaAddress;
  final String ethSepoliaTransferRecipientAddress;
  final String ethSepoliaTransferAmount;
  final String fundedBscTestnetMnemonic;
  final String fundedBscTestnetAddress;
  final String bscTestnetTransferRecipientAddress;
  final String bscTestnetTransferAmount;
  final String fundedPolygonTestnetMnemonic;
  final String fundedPolygonTestnetAddress;
  final String polygonTestnetTransferRecipientAddress;
  final String polygonTestnetTransferAmount;
  final String fundedBaseTestnetMnemonic;
  final String fundedBaseTestnetAddress;
  final String baseTestnetTransferRecipientAddress;
  final String baseTestnetTransferAmount;
  final String fundedArbitrumTestnetMnemonic;
  final String fundedArbitrumTestnetAddress;
  final String arbitrumTestnetTransferRecipientAddress;
  final String arbitrumTestnetTransferAmount;
  final String fundedOptimismTestnetMnemonic;
  final String fundedOptimismTestnetAddress;
  final String optimismTestnetTransferRecipientAddress;
  final String optimismTestnetTransferAmount;
  final String fundedXrpTestnetMnemonic;
  final String fundedXrpTestnetAddress;
  final String xrpTestnetTransferRecipientAddress;
  final String xrpTestnetTransferAmount;
  final String xrpTestnetTransferDestinationTag;
  final String fundedSolDevnetMnemonic;
  final String fundedSolDevnetAddress;
  final String solDevnetTransferRecipientAddress;
  final String solDevnetTransferAmount;
  final String fundedSuiTestnetMnemonic;
  final String fundedSuiTestnetAddress;
  final String suiTestnetTransferRecipientAddress;
  final String suiTestnetTransferAmount;
  final String fundedTonTestnetMnemonic;
  final String fundedTonTestnetAddress;
  final String tonTestnetTransferRecipientAddress;
  final String tonTestnetTransferAmount;
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
    final btcAmount = json['btcTestnetTransferAmount']?.toString().trim() ?? '';
    final dogeAmount =
        json['dogeTestnetTransferAmount']?.toString().trim() ?? '';
    final bchAmount = json['bchTestnetTransferAmount']?.toString().trim() ?? '';
    final ltcAmount = json['ltcTestnetTransferAmount']?.toString().trim() ?? '';
    final ethAmount = json['ethSepoliaTransferAmount']?.toString().trim() ?? '';
    final bscAmount = json['bscTestnetTransferAmount']?.toString().trim() ?? '';
    final polygonAmount =
        json['polygonTestnetTransferAmount']?.toString().trim() ?? '';
    final baseAmount =
        json['baseTestnetTransferAmount']?.toString().trim() ?? '';
    final arbitrumAmount =
        json['arbitrumTestnetTransferAmount']?.toString().trim() ?? '';
    final optimismAmount =
        json['optimismTestnetTransferAmount']?.toString().trim() ?? '';
    final xrpAmount = json['xrpTestnetTransferAmount']?.toString().trim() ?? '';
    final solAmount = json['solDevnetTransferAmount']?.toString().trim() ?? '';
    final suiAmount = json['suiTestnetTransferAmount']?.toString().trim() ?? '';
    final tonAmount = json['tonTestnetTransferAmount']?.toString().trim() ?? '';
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
      fundedBtcTestnetMnemonic:
          json['fundedBtcTestnetMnemonic']?.toString().trim() ?? '',
      fundedBtcTestnetAddress:
          json['fundedBtcTestnetAddress']?.toString().trim() ?? '',
      btcTestnetTransferRecipientAddress:
          json['btcTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      btcTestnetTransferAmount: btcAmount.isEmpty ? '0.0001' : btcAmount,
      fundedDogeTestnetMnemonic:
          json['fundedDogeTestnetMnemonic']?.toString().trim() ?? '',
      fundedDogeTestnetAddress:
          json['fundedDogeTestnetAddress']?.toString().trim() ?? '',
      dogeTestnetTransferRecipientAddress:
          json['dogeTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      dogeTestnetTransferAmount: dogeAmount.isEmpty ? '1' : dogeAmount,
      fundedBchTestnetMnemonic:
          json['fundedBchTestnetMnemonic']?.toString().trim() ?? '',
      fundedBchTestnetAddress:
          json['fundedBchTestnetAddress']?.toString().trim() ?? '',
      bchTestnetTransferRecipientAddress:
          json['bchTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      bchTestnetTransferAmount: bchAmount.isEmpty ? '0.001' : bchAmount,
      fundedLtcTestnetMnemonic:
          json['fundedLtcTestnetMnemonic']?.toString().trim() ?? '',
      fundedLtcTestnetAddress:
          json['fundedLtcTestnetAddress']?.toString().trim() ?? '',
      ltcTestnetTransferRecipientAddress:
          json['ltcTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      ltcTestnetTransferAmount: ltcAmount.isEmpty ? '0.001' : ltcAmount,
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
      fundedBscTestnetMnemonic:
          json['fundedBscTestnetMnemonic']?.toString().trim() ?? '',
      fundedBscTestnetAddress:
          json['fundedBscTestnetAddress']?.toString().trim() ?? '',
      bscTestnetTransferRecipientAddress:
          json['bscTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      bscTestnetTransferAmount: bscAmount.isEmpty ? '0.001' : bscAmount,
      fundedPolygonTestnetMnemonic:
          json['fundedPolygonTestnetMnemonic']?.toString().trim() ?? '',
      fundedPolygonTestnetAddress:
          json['fundedPolygonTestnetAddress']?.toString().trim() ?? '',
      polygonTestnetTransferRecipientAddress:
          json['polygonTestnetTransferRecipientAddress']?.toString().trim() ??
          '',
      polygonTestnetTransferAmount: polygonAmount.isEmpty
          ? '0.001'
          : polygonAmount,
      fundedBaseTestnetMnemonic:
          json['fundedBaseTestnetMnemonic']?.toString().trim() ?? '',
      fundedBaseTestnetAddress:
          json['fundedBaseTestnetAddress']?.toString().trim() ?? '',
      baseTestnetTransferRecipientAddress:
          json['baseTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      baseTestnetTransferAmount: baseAmount.isEmpty ? '0.0001' : baseAmount,
      fundedArbitrumTestnetMnemonic:
          json['fundedArbitrumTestnetMnemonic']?.toString().trim() ?? '',
      fundedArbitrumTestnetAddress:
          json['fundedArbitrumTestnetAddress']?.toString().trim() ?? '',
      arbitrumTestnetTransferRecipientAddress:
          json['arbitrumTestnetTransferRecipientAddress']?.toString().trim() ??
          '',
      arbitrumTestnetTransferAmount: arbitrumAmount.isEmpty
          ? '0.0001'
          : arbitrumAmount,
      fundedOptimismTestnetMnemonic:
          json['fundedOptimismTestnetMnemonic']?.toString().trim() ?? '',
      fundedOptimismTestnetAddress:
          json['fundedOptimismTestnetAddress']?.toString().trim() ?? '',
      optimismTestnetTransferRecipientAddress:
          json['optimismTestnetTransferRecipientAddress']?.toString().trim() ??
          '',
      optimismTestnetTransferAmount: optimismAmount.isEmpty
          ? '0.0001'
          : optimismAmount,
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
      fundedSuiTestnetMnemonic:
          json['fundedSuiTestnetMnemonic']?.toString().trim() ?? '',
      fundedSuiTestnetAddress:
          json['fundedSuiTestnetAddress']?.toString().trim() ?? '',
      suiTestnetTransferRecipientAddress:
          json['suiTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      suiTestnetTransferAmount: suiAmount.isEmpty ? '0.01' : suiAmount,
      fundedTonTestnetMnemonic:
          json['fundedTonTestnetMnemonic']?.toString().trim() ?? '',
      fundedTonTestnetAddress:
          json['fundedTonTestnetAddress']?.toString().trim() ?? '',
      tonTestnetTransferRecipientAddress:
          json['tonTestnetTransferRecipientAddress']?.toString().trim() ?? '',
      tonTestnetTransferAmount: tonAmount.isEmpty ? '0.05' : tonAmount,
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

  bool get hasFundedBtcTestnetWallet =>
      fundedBtcTestnetMnemonic.isNotEmpty &&
      fundedBtcTestnetAddress.isNotEmpty &&
      btcTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedDogeTestnetWallet =>
      fundedDogeTestnetMnemonic.isNotEmpty &&
      fundedDogeTestnetAddress.isNotEmpty &&
      dogeTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedBchTestnetWallet =>
      fundedBchTestnetMnemonic.isNotEmpty &&
      fundedBchTestnetAddress.isNotEmpty &&
      bchTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedLtcTestnetWallet =>
      fundedLtcTestnetMnemonic.isNotEmpty &&
      fundedLtcTestnetAddress.isNotEmpty &&
      ltcTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedAptTestnetWallet =>
      fundedAptTestnetMnemonic.isNotEmpty &&
      fundedAptTestnetAddress.isNotEmpty &&
      aptTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedEthSepoliaWallet =>
      fundedEthSepoliaMnemonic.isNotEmpty &&
      fundedEthSepoliaAddress.isNotEmpty &&
      ethSepoliaTransferRecipientAddress.isNotEmpty;

  bool get hasFundedBscTestnetWallet =>
      fundedBscTestnetMnemonic.isNotEmpty &&
      fundedBscTestnetAddress.isNotEmpty &&
      bscTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedPolygonTestnetWallet =>
      fundedPolygonTestnetMnemonic.isNotEmpty &&
      fundedPolygonTestnetAddress.isNotEmpty &&
      polygonTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedBaseTestnetWallet =>
      fundedBaseTestnetMnemonic.isNotEmpty &&
      fundedBaseTestnetAddress.isNotEmpty &&
      baseTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedArbitrumTestnetWallet =>
      fundedArbitrumTestnetMnemonic.isNotEmpty &&
      fundedArbitrumTestnetAddress.isNotEmpty &&
      arbitrumTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedOptimismTestnetWallet =>
      fundedOptimismTestnetMnemonic.isNotEmpty &&
      fundedOptimismTestnetAddress.isNotEmpty &&
      optimismTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedXrpTestnetWallet =>
      fundedXrpTestnetMnemonic.isNotEmpty &&
      fundedXrpTestnetAddress.isNotEmpty &&
      xrpTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedSolDevnetWallet =>
      fundedSolDevnetMnemonic.isNotEmpty &&
      fundedSolDevnetAddress.isNotEmpty &&
      solDevnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedSuiTestnetWallet =>
      fundedSuiTestnetMnemonic.isNotEmpty &&
      fundedSuiTestnetAddress.isNotEmpty &&
      suiTestnetTransferRecipientAddress.isNotEmpty;

  bool get hasFundedTonTestnetWallet =>
      fundedTonTestnetMnemonic.isNotEmpty &&
      fundedTonTestnetAddress.isNotEmpty &&
      tonTestnetTransferRecipientAddress.isNotEmpty;

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
      hasFundedBtcTestnetWallet ||
      hasFundedDogeTestnetWallet ||
      hasFundedBchTestnetWallet ||
      hasFundedLtcTestnetWallet ||
      hasFundedAptTestnetWallet ||
      hasFundedEthSepoliaWallet ||
      hasFundedBscTestnetWallet ||
      hasFundedPolygonTestnetWallet ||
      hasFundedBaseTestnetWallet ||
      hasFundedArbitrumTestnetWallet ||
      hasFundedOptimismTestnetWallet ||
      hasFundedXrpTestnetWallet ||
      hasFundedSolDevnetWallet ||
      hasFundedSuiTestnetWallet ||
      hasFundedTonTestnetWallet ||
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
