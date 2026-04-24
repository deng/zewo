import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/wallet.dart';

import 'evm_offline_sign_page.dart';
import 'evm_offline_verify_page.dart';
import 'sol_offline_verify_page.dart';

class OfflineToolsPage extends StatelessWidget {
  OfflineToolsPage({super.key, OfflineSignVerifyService? service})
    : service = service ?? OfflineSignVerifyService();

  final OfflineSignVerifyService service;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '签名工具',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '工具入口按当前共享 SignerAdapter capability 动态展示；当前版本重点覆盖 EVM 签名/验签和 SOL 验签。',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<_ToolCardConfig>>(
              future: _loadToolCards(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    '工具能力加载失败：${snapshot.error}',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }

                final cards = snapshot.data ?? const <_ToolCardConfig>[];
                if (cards.isEmpty) {
                  return Text(
                    '当前没有可用的离线签名或验签能力。',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      _ActionCard(
                        key: Key('offline_tools_action_$i'),
                        title: cards[i].title,
                        subtitle: cards[i].subtitle,
                        icon: cards[i].icon,
                        onTap: cards[i].onTap,
                      ),
                      if (i != cards.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<_ToolCardConfig>> _loadToolCards(BuildContext context) async {
    final wallet = context.read<WalletProvider>().currentWallet;
    final cards = <_ToolCardConfig>[];

    if (wallet != null && _isEvmChain(wallet.chainType)) {
      final capabilities = await service.capabilities(
        chainType: wallet.chainType,
        networkType: wallet.networkType,
      );

      final supportsEvmMessageSign = capabilities.supportsSign(
        payloadType: SignaturePayloadType.message,
        signingStandard: SigningStandard.evmEip191PersonalSignV1,
      );
      final supportsEvmTypedDataSign = capabilities.supportsSign(
        payloadType: SignaturePayloadType.typedData,
        signingStandard: SigningStandard.evmEip712TypedDataV4,
      );
      final supportsEvmTransactionSign = capabilities.supportsSign(
        payloadType: SignaturePayloadType.transaction,
        signingStandard: SigningStandard.evmTransactionV1,
      );

      if (supportsEvmMessageSign ||
          supportsEvmTypedDataSign ||
          supportsEvmTransactionSign) {
        cards.add(
          _ToolCardConfig(
            title: '离线签名',
            subtitle: '使用当前 EVM 钱包对消息、Typed Data 或交易 payload 进行本地签名。',
            icon: Icons.edit_note,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => EvmOfflineSignPage()),
              );
            },
          ),
        );
      }

      final supportsEvmVerify =
          capabilities.supportsVerify(
            payloadType: SignaturePayloadType.message,
            signingStandard: SigningStandard.evmEip191PersonalSignV1,
          ) ||
          capabilities.supportsVerify(
            payloadType: SignaturePayloadType.typedData,
            signingStandard: SigningStandard.evmEip712TypedDataV4,
          ) ||
          capabilities.supportsVerify(
            payloadType: SignaturePayloadType.transaction,
            signingStandard: SigningStandard.evmTransactionV1,
          );

      if (supportsEvmVerify) {
        cards.add(
          _ToolCardConfig(
            title: '离线验签',
            subtitle: '对已签名的 EVM payload 做本地密码学验签和 signer 匹配。',
            icon: Icons.verified_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => EvmOfflineVerifyPage()),
              );
            },
          ),
        );
      }
    }

    final solCapabilities = await service.capabilities(
      chainType: ChainType.sol,
      networkType: NetworkType.mainnet,
    );
    final supportsSolVerify = solCapabilities.supportsVerify(
      payloadType: SignaturePayloadType.message,
      signingStandard: SigningStandard.walletEd25519RawV1,
    );
    if (supportsSolVerify) {
      cards.add(
        _ToolCardConfig(
          title: 'SOL 验签',
          subtitle: '对 Solana raw message 签名做本地 Ed25519 验签和地址匹配。',
          icon: Icons.key_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SolOfflineVerifyPage()),
            );
          },
        ),
      );
    }

    return cards;
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCardConfig {
  const _ToolCardConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
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
