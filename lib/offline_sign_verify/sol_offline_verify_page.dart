import 'package:flutter/material.dart';
import 'package:wallet/wallet.dart';

import 'evm_offline_result_page.dart';

class SolOfflineVerifyPage extends StatefulWidget {
  SolOfflineVerifyPage({super.key, OfflineSignVerifyService? service})
    : service = service ?? OfflineSignVerifyService();

  final OfflineSignVerifyService service;

  @override
  State<SolOfflineVerifyPage> createState() => _SolOfflineVerifyPageState();
}

class _SolOfflineVerifyPageState extends State<SolOfflineVerifyPage> {
  final _payloadController = TextEditingController();
  final _signatureController = TextEditingController();
  final _publicKeyController = TextEditingController();
  final _expectedAddressController = TextEditingController();
  PayloadEncoding _payloadEncoding = PayloadEncoding.utf8;
  SignatureEncoding _signatureEncoding = SignatureEncoding.hex;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _payloadController.dispose();
    _signatureController.dispose();
    _publicKeyController.dispose();
    _expectedAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('SOL 离线验签')),
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
                  'Solana Raw Message Verify',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前只支持 message + wallet_ed25519_raw_v1，且需要显式提供 signer public key。',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PayloadEncoding>(
                  value: _payloadEncoding,
                  items: const [
                    DropdownMenuItem(
                      value: PayloadEncoding.utf8,
                      child: Text('Payload: UTF-8'),
                    ),
                    DropdownMenuItem(
                      value: PayloadEncoding.hex,
                      child: Text('Payload: Hex'),
                    ),
                    DropdownMenuItem(
                      value: PayloadEncoding.base64,
                      child: Text('Payload: Base64'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _payloadEncoding = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SignatureEncoding>(
                  value: _signatureEncoding,
                  items: const [
                    DropdownMenuItem(
                      value: SignatureEncoding.hex,
                      child: Text('Signature: Hex'),
                    ),
                    DropdownMenuItem(
                      value: SignatureEncoding.base64,
                      child: Text('Signature: Base64'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _signatureEncoding = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInputCard(
            title: '消息内容',
            body: '输入待验证的原始消息 payload。',
            controller: _payloadController,
            minLines: 6,
            maxLines: 12,
            hintText: 'hello sol',
          ),
          const SizedBox(height: 16),
          _buildInputCard(
            title: '签名',
            body: '按上方编码输入签名内容。',
            controller: _signatureController,
            minLines: 4,
            maxLines: 8,
            hintText: '0x...',
          ),
          const SizedBox(height: 16),
          _buildInputCard(
            title: 'Signer Public Key',
            body: '请输入 signer 的 32-byte Ed25519 公钥 hex。',
            controller: _publicKeyController,
            minLines: 3,
            maxLines: 6,
            hintText: '0x...',
          ),
          const SizedBox(height: 16),
          _buildInputCard(
            title: '期望地址',
            body: '可选。填写后会校验解析出的 SOL 地址是否一致。',
            controller: _expectedAddressController,
            minLines: 2,
            maxLines: 4,
            hintText: '5nX1...',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('sol_offline_verify_submit_button'),
            onPressed: _isSubmitting ? null : _verify,
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
            key: switch (title) {
              '签名' => const Key('sol_offline_verify_signature_field'),
              'Signer Public Key' => const Key(
                'sol_offline_verify_public_key_field',
              ),
              '期望地址' => const Key('sol_offline_verify_expected_address_field'),
              _ => const Key('sol_offline_verify_payload_field'),
            },
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hintText),
          ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
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
    if (_publicKeyController.text.trim().isEmpty) {
      setState(() {
        _error = '请输入 signer public key。';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final request = OfflineSignVerifyService.buildVerifyPayloadRequest(
        chainType: ChainType.sol,
        networkType: NetworkType.mainnet,
        payloadType: SignaturePayloadType.message,
        payload: _payloadController.text.trim(),
        payloadEncoding: _payloadEncoding,
        signingStandard: SigningStandard.walletEd25519RawV1,
        signature: _signatureController.text.trim(),
        signatureEncoding: _signatureEncoding,
        signerPublicKey: _publicKeyController.text.trim(),
        expectedSignerAddress: _expectedAddressController.text.trim().isEmpty
            ? null
            : _expectedAddressController.text.trim(),
      );

      final result = await widget.service.verify(request);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EvmOfflineResultPage(
            title: 'SOL 验签结果',
            sections: [
              buildResultSection('验证状态', {
                'Signature Valid': result.signatureValid.toString(),
                'Signer Matched': result.signerMatched.toString(),
                if (result.resolvedSignerAddress != null)
                  'Resolved Address': result.resolvedSignerAddress!,
                if (result.resolvedSignerPublicKey != null)
                  'Resolved Public Key': result.resolvedSignerPublicKey!,
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
}
