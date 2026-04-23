import 'package:flutter/material.dart';

class EvmOfflineResultPage extends StatelessWidget {
  const EvmOfflineResultPage({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<_ResultSection> sections;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final section = sections[index];
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
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...section.rows.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          row.value,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: sections.length,
      ),
    );
  }
}

class _ResultSection {
  const _ResultSection({required this.title, required this.rows});

  final String title;
  final List<_ResultRow> rows;
}

class _ResultRow {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;
}

_ResultSection buildResultSection(String title, Map<String, String> rows) {
  return _ResultSection(
    title: title,
    rows: rows.entries
        .map((entry) => _ResultRow(label: entry.key, value: entry.value))
        .toList(growable: false),
  );
}
