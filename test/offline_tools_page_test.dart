import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

class _FakeWalletProvider extends WalletProvider {
  _FakeWalletProvider(this._walletInfo);

  final WalletInfo? _walletInfo;

  @override
  bool get isLoading => false;

  @override
  WalletInfo? get currentWallet => _walletInfo;
}

class _FakeCapabilityService extends OfflineSignVerifyService {
  _FakeCapabilityService(this._capabilitiesByChain);

  final Map<ChainType, SignerAdapterCapabilities> _capabilitiesByChain;

  @override
  Future<SignerAdapterCapabilities> capabilities({
    required ChainType chainType,
    required NetworkType networkType,
  }) async {
    final capabilities = _capabilitiesByChain[chainType];
    if (capabilities == null) {
      throw SignerAdapterFailure(
        failureCode: SignerFailureCode.unsupportedChain,
        message: 'unsupported',
      );
    }
    return capabilities;
  }
}

void main() {
  testWidgets('OfflineToolsPage renders cards from capabilities', (
    WidgetTester tester,
  ) async {
    final wallet = WalletInfo(
      id: 'wallet-1',
      name: 'EVM Wallet',
      createdAt: DateTime.utc(2026, 1, 1),
      type: WalletType.mnemonic,
      chainType: ChainType.eth,
      networkType: NetworkType.mainnet,
      architectureType: BlockchainArchitecture.evm,
      chainId: '1',
      defaultAddressIndex: 0,
      mnemonicId: 'mnemonic-1',
    );
    wallet.updateDefaultAddress(
      CryptoAddress(
        id: 'address-1',
        address: '0xabc',
        addressLower: '0xabc',
        chainType: ChainType.eth,
        networkType: NetworkType.mainnet,
        architectureType: BlockchainArchitecture.evm,
        derivationMode: DerivationMode.mnemonic,
        accountIndex: 0,
        changeIndex: 0,
        addressIndex: 0,
        publicKey: '',
        path: '',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final service = _FakeCapabilityService({
      ChainType.eth: const SignerAdapterCapabilities(
        chainType: ChainType.eth,
        networkType: NetworkType.mainnet,
        operations: <SignerOperationCapability>[
          SignerOperationCapability(
            payloadType: SignaturePayloadType.message,
            signingStandard: SigningStandard.evmEip191PersonalSignV1,
            supportsSign: true,
            supportsVerify: true,
          ),
          SignerOperationCapability(
            payloadType: SignaturePayloadType.typedData,
            signingStandard: SigningStandard.evmEip712TypedDataV4,
            supportsSign: true,
            supportsVerify: true,
          ),
          SignerOperationCapability(
            payloadType: SignaturePayloadType.transaction,
            signingStandard: SigningStandard.evmTransactionV1,
            supportsSign: true,
            supportsVerify: true,
          ),
        ],
        supportedPayloadEncodings: <PayloadEncoding>[
          PayloadEncoding.utf8,
          PayloadEncoding.json,
        ],
        supportedSignatureEncodings: <SignatureEncoding>[SignatureEncoding.hex],
      ),
      ChainType.sol: const SignerAdapterCapabilities(
        chainType: ChainType.sol,
        networkType: NetworkType.mainnet,
        operations: <SignerOperationCapability>[
          SignerOperationCapability(
            payloadType: SignaturePayloadType.message,
            signingStandard: SigningStandard.walletEd25519RawV1,
            supportsSign: false,
            supportsVerify: true,
          ),
        ],
        supportedPayloadEncodings: <PayloadEncoding>[PayloadEncoding.utf8],
        supportedSignatureEncodings: <SignatureEncoding>[SignatureEncoding.hex],
      ),
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<WalletProvider>.value(
        value: _FakeWalletProvider(wallet),
        child: MaterialApp(home: OfflineToolsPage(service: service)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('离线签名'), findsOneWidget);
    expect(find.text('离线验签'), findsOneWidget);
    expect(find.text('SOL 验签'), findsOneWidget);
  });
}
