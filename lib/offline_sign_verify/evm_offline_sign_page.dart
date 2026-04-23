import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

import 'evm_offline_result_page.dart';

enum _SignPayloadKind {
  message('消息', SignaturePayloadType.message),
  typedData('Typed Data v4', SignaturePayloadType.typedData),
  transaction('交易', SignaturePayloadType.transaction);

  const _SignPayloadKind(this.label, this.payloadType);

  final String label;
  final SignaturePayloadType payloadType;
}

class EvmOfflineSignPage extends StatefulWidget {
  const EvmOfflineSignPage({super.key});

  @override
  State<EvmOfflineSignPage> createState() => _EvmOfflineSignPageState();
}

class _EvmOfflineSignPageState extends State<EvmOfflineSignPage> {
  final _payloadController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = OfflineSignVerifyService();
  _SignPayloadKind _payloadKind = _SignPayloadKind.message;
  PayloadEncoding _messageEncoding = PayloadEncoding.utf8;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _payloadController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final walletInfo = walletProvider.currentWallet;
    final signer = walletInfo?.defaultAddress;
    final isEvmWallet =
        walletInfo != null &&
        signer != null &&
        _isEvmChain(walletInfo.chainType);

    return Scaffold(
      appBar: AppBar(title: const Text('离线签名')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWalletCard(walletInfo, signer, isEvmWallet),
          const SizedBox(height: 16),
          _buildPayloadTypeCard(),
          const SizedBox(height: 16),
          _buildPayloadInputCard(),
          const SizedBox(height: 16),
          _buildPasswordCard(),
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
            onPressed: !isEvmWallet || _isSubmitting
                ? null
                : () => _sign(context),
            child: Text(_isSubmitting ? '签名中...' : '开始签名'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    WalletInfo? walletInfo,
    CryptoAddress? signer,
    bool isEvmWallet,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = walletInfo == null
        ? '当前没有可用钱包'
        : isEvmWallet
        ? '当前 EVM 钱包'
        : '当前钱包不是 EVM 链';
    final subtitle = walletInfo == null
        ? '请先创建或导入一个 EVM 钱包。'
        : isEvmWallet
        ? '${walletInfo.name}\n${signer?.address ?? ''}'
        : '${walletInfo.name}\n当前链：${walletInfo.chainType.name}';

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
          Text(subtitle),
        ],
      ),
    );
  }

  Widget _buildPayloadTypeCard() {
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
            'Payload 类型',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<_SignPayloadKind>(
            value: _payloadKind,
            items: _SignPayloadKind.values
                .map(
                  (kind) => DropdownMenuItem<_SignPayloadKind>(
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
          if (_payloadKind == _SignPayloadKind.message) ...[
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
                  _error = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayloadInputCard() {
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
            _payloadHintTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(_payloadHintBody),
          const SizedBox(height: 12),
          TextField(
            controller: _payloadController,
            minLines: 8,
            maxLines: 16,
            decoration: InputDecoration(hintText: _payloadHintPlaceholder),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
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
            '钱包密码',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: '输入当前钱包密码以完成签名'),
          ),
        ],
      ),
    );
  }

  Future<void> _sign(BuildContext context) async {
    final walletInfo = context.read<WalletProvider>().currentWallet;
    final signer = walletInfo?.defaultAddress;
    if (walletInfo == null ||
        signer == null ||
        !_isEvmChain(walletInfo.chainType)) {
      setState(() {
        _error = '当前没有可用于 EVM 签名的钱包。';
      });
      return;
    }
    if (_payloadController.text.trim().isEmpty) {
      setState(() {
        _error = '请输入需要签名的 payload。';
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _error = '请输入钱包密码。';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final request = OfflineSignVerifyService.buildSignPayloadRequest(
        walletInfo: walletInfo,
        signer: signer,
        payloadType: _payloadKind.payloadType,
        payload: _payloadController.text.trim(),
        payloadEncoding: _payloadEncoding,
        signingStandard: _signingStandard,
      );
      final result = await _service.sign(
        request,
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EvmOfflineResultPage(
            title: '签名结果',
            sections: [
              buildResultSection('基础信息', {
                '链': walletInfo.chainType.name,
                '标准': result.signingStandard.wireValue,
                '类型': result.payloadType.wireValue,
                if (result.resolvedSignerAddress != null)
                  '签名地址': result.resolvedSignerAddress!,
              }),
              buildResultSection('输出', {
                '签名': result.signature,
                if (result.digest != null) 'Digest': result.digest!,
                if (result.signedPayload != null)
                  'Signed Payload': result.signedPayload!,
                if (result.transactionHash != null)
                  'Transaction Hash': result.transactionHash!,
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
      case _SignPayloadKind.message:
        return _messageEncoding;
      case _SignPayloadKind.typedData:
      case _SignPayloadKind.transaction:
        return PayloadEncoding.json;
    }
  }

  SigningStandard get _signingStandard {
    switch (_payloadKind) {
      case _SignPayloadKind.message:
        return SigningStandard.evmEip191PersonalSignV1;
      case _SignPayloadKind.typedData:
        return SigningStandard.evmEip712TypedDataV4;
      case _SignPayloadKind.transaction:
        return SigningStandard.evmTransactionV1;
    }
  }

  String get _payloadHintTitle {
    switch (_payloadKind) {
      case _SignPayloadKind.message:
        return '消息内容';
      case _SignPayloadKind.typedData:
        return 'Typed Data JSON';
      case _SignPayloadKind.transaction:
        return '交易 JSON';
    }
  }

  String get _payloadHintBody {
    switch (_payloadKind) {
      case _SignPayloadKind.message:
        return '支持 UTF-8、Hex、Base64 三种输入形式。';
      case _SignPayloadKind.typedData:
        return '请粘贴完整的 EIP-712 Typed Data JSON。';
      case _SignPayloadKind.transaction:
        return '请粘贴符合当前适配器要求的 EVM unsigned transaction JSON。';
    }
  }

  String get _payloadHintPlaceholder {
    switch (_payloadKind) {
      case _SignPayloadKind.message:
        return '输入待签名消息';
      case _SignPayloadKind.typedData:
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
      case _SignPayloadKind.transaction:
        return jsonEncode({
          'type': '0x2',
          'chainId': '0x1',
          'nonce': '0x0',
          'maxPriorityFeePerGas': '0x59682f00',
          'maxFeePerGas': '0x59682f10',
          'gas': '0x5208',
          'to': '0x000000000000000000000000000000000000dead',
          'value': '0x1',
          'data': '0x',
          'accessList': [],
        });
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
