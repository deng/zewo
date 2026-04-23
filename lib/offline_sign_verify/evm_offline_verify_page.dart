import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

import 'evm_offline_result_page.dart';

enum _VerifyPayloadKind {
  message('消息', SignaturePayloadType.message),
  typedData('Typed Data v4', SignaturePayloadType.typedData),
  transaction('交易', SignaturePayloadType.transaction);

  const _VerifyPayloadKind(this.label, this.payloadType);

  final String label;
  final SignaturePayloadType payloadType;
}

class EvmOfflineVerifyPage extends StatefulWidget {
  const EvmOfflineVerifyPage({super.key});

  @override
  State<EvmOfflineVerifyPage> createState() => _EvmOfflineVerifyPageState();
}

class _EvmOfflineVerifyPageState extends State<EvmOfflineVerifyPage> {
  final _payloadController = TextEditingController();
  final _signatureController = TextEditingController();
  final _expectedAddressController = TextEditingController();
  final _service = OfflineSignVerifyService();
  _VerifyPayloadKind _payloadKind = _VerifyPayloadKind.message;
  PayloadEncoding _messageEncoding = PayloadEncoding.utf8;
  ChainType _selectedChain = ChainType.eth;
  NetworkType _selectedNetwork = NetworkType.mainnet;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _payloadController.dispose();
    _signatureController.dispose();
    _expectedAddressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final walletInfo = context.read<WalletProvider>().currentWallet;
    final address = walletInfo?.defaultAddress?.address;
    if (_expectedAddressController.text.isEmpty &&
        walletInfo != null &&
        _isEvmChain(walletInfo.chainType) &&
        address != null) {
      _expectedAddressController.text = address;
      _selectedChain = walletInfo.chainType;
      _selectedNetwork = walletInfo.networkType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('离线验签')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVM 验签参数',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ChainType>(
                  value: _selectedChain,
                  items: const [
                    DropdownMenuItem(
                      value: ChainType.eth,
                      child: Text('Ethereum'),
                    ),
                    DropdownMenuItem(value: ChainType.bsc, child: Text('BSC')),
                    DropdownMenuItem(
                      value: ChainType.polygon,
                      child: Text('Polygon'),
                    ),
                    DropdownMenuItem(
                      value: ChainType.base,
                      child: Text('Base'),
                    ),
                    DropdownMenuItem(
                      value: ChainType.arbitrum,
                      child: Text('Arbitrum'),
                    ),
                    DropdownMenuItem(
                      value: ChainType.optimism,
                      child: Text('Optimism'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedChain = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<NetworkType>(
                  value: _selectedNetwork,
                  items: const [
                    DropdownMenuItem(
                      value: NetworkType.mainnet,
                      child: Text('Mainnet'),
                    ),
                    DropdownMenuItem(
                      value: NetworkType.testnet,
                      child: Text('Testnet'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedNetwork = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_VerifyPayloadKind>(
                  value: _payloadKind,
                  items: _VerifyPayloadKind.values
                      .map(
                        (kind) => DropdownMenuItem<_VerifyPayloadKind>(
                          value: kind,
                          child: Text(kind.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _payloadKind = value;
                      _error = null;
                    });
                  },
                ),
                if (_payloadKind == _VerifyPayloadKind.message) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PayloadEncoding>(
                    value: _messageEncoding,
                    items: const [
                      DropdownMenuItem(
                        value: PayloadEncoding.utf8,
                        child: Text('UTF-8'),
                      ),
                      DropdownMenuItem(
                        value: PayloadEncoding.hex,
                        child: Text('Hex'),
                      ),
                      DropdownMenuItem(
                        value: PayloadEncoding.base64,
                        child: Text('Base64'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _messageEncoding = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInputCard(
            title: _payloadHintTitle,
            body: _payloadHintBody,
            controller: _payloadController,
            minLines: 8,
            maxLines: 16,
            hintText: _payloadHintPlaceholder,
          ),
          const SizedBox(height: 16),
          _buildInputCard(
            title: '签名',
            body: '请输入 0x 开头的 hex 签名结果。',
            controller: _signatureController,
            minLines: 4,
            maxLines: 8,
            hintText: '0x...',
          ),
          const SizedBox(height: 16),
          _buildInputCard(
            title: '期望签名地址',
            body: '可选。填写后会额外校验恢复出的地址是否匹配。',
            controller: _expectedAddressController,
            minLines: 2,
            maxLines: 4,
            hintText: '0x...',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _verify(context),
            child: Text(_isSubmitting ? '验证中...' : '开始验证'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required String body,
    required TextEditingController controller,
    required int minLines,
    required int maxLines,
    required String hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(body),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hintText),
          ),
        ],
      ),
    );
  }

  Future<void> _verify(BuildContext context) async {
    if (_payloadController.text.trim().isEmpty) {
      setState(() {
        _error = '请输入需要验证的 payload。';
      });
      return;
    }
    if (_signatureController.text.trim().isEmpty) {
      setState(() {
        _error = '请输入签名。';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final request = OfflineSignVerifyService.buildVerifyPayloadRequest(
        chainType: _selectedChain,
        networkType: _selectedNetwork,
        payloadType: _payloadKind.payloadType,
        payload: _payloadController.text.trim(),
        payloadEncoding: _payloadEncoding,
        signingStandard: _signingStandard,
        signature: _signatureController.text.trim(),
        expectedSignerAddress: _expectedAddressController.text.trim().isEmpty
            ? null
            : _expectedAddressController.text.trim(),
      );
      final result = await _service.verify(request);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EvmOfflineResultPage(
            title: '验签结果',
            sections: [
              buildResultSection('验证状态', {
                'Signature Valid': result.signatureValid.toString(),
                'Signer Matched': result.signerMatched.toString(),
                if (result.resolvedSignerAddress != null)
                  'Resolved Address': result.resolvedSignerAddress!,
                if (result.resolvedSignerPublicKey != null)
                  'Resolved Public Key': result.resolvedSignerPublicKey!,
                if (result.digest != null) 'Digest': result.digest!,
                if (result.transactionHash != null)
                  'Transaction Hash': result.transactionHash!,
                if (result.warnings.isNotEmpty)
                  'Warnings': result.warnings.join('\n'),
              }),
            ],
          ),
        ),
      );
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  PayloadEncoding get _payloadEncoding {
    switch (_payloadKind) {
      case _VerifyPayloadKind.message:
        return _messageEncoding;
      case _VerifyPayloadKind.typedData:
      case _VerifyPayloadKind.transaction:
        return PayloadEncoding.json;
    }
  }

  SigningStandard get _signingStandard {
    switch (_payloadKind) {
      case _VerifyPayloadKind.message:
        return SigningStandard.evmEip191PersonalSignV1;
      case _VerifyPayloadKind.typedData:
        return SigningStandard.evmEip712TypedDataV4;
      case _VerifyPayloadKind.transaction:
        return SigningStandard.evmTransactionV1;
    }
  }

  String get _payloadHintTitle {
    switch (_payloadKind) {
      case _VerifyPayloadKind.message:
        return '消息内容';
      case _VerifyPayloadKind.typedData:
        return 'Typed Data JSON';
      case _VerifyPayloadKind.transaction:
        return 'Signed Transaction';
    }
  }

  String get _payloadHintBody {
    switch (_payloadKind) {
      case _VerifyPayloadKind.message:
        return '支持 UTF-8、Hex、Base64 三种输入形式。';
      case _VerifyPayloadKind.typedData:
        return '请粘贴完整的 EIP-712 Typed Data JSON。';
      case _VerifyPayloadKind.transaction:
        return '请粘贴 signed raw transaction hex。';
    }
  }

  String get _payloadHintPlaceholder {
    switch (_payloadKind) {
      case _VerifyPayloadKind.message:
        return '输入待验证消息';
      case _VerifyPayloadKind.typedData:
        return jsonEncode({
          'types': {
            'EIP712Domain': [
              {'name': 'name', 'type': 'string'},
            ],
            'Mail': [
              {'name': 'contents', 'type': 'string'},
            ],
          },
          'primaryType': 'Mail',
          'domain': {'name': 'Demo'},
          'message': {'contents': 'Hello'},
        });
      case _VerifyPayloadKind.transaction:
        return '0x02...';
    }
  }
}

bool _isEvmChain(ChainType chainType) {
  switch (chainType) {
    case ChainType.eth:
    case ChainType.bsc:
    case ChainType.polygon:
    case ChainType.base:
    case ChainType.arbitrum:
    case ChainType.optimism:
      return true;
    default:
      return false;
  }
}
