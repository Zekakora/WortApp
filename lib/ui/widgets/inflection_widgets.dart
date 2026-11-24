import 'package:flutter/material.dart';
import '../../core/i18n/app_localizations.dart';
import '../../services/dictionary/dictionary_engine.dart';

/// 变格卡片：单个时态分组（标题 + 6 人称变位）
///
/// 与 AI 查词界面 / 单词详情页共用，保证两处展示样式一致
class InflectionTenseBlock extends StatelessWidget {
  final String zhLabel;
  final String deLabel;
  final String? header;
  final Map<String, String> persons;

  const InflectionTenseBlock({
    super.key,
    required this.zhLabel,
    required this.deLabel,
    this.header,
    required this.persons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$zhLabel ($deLabel)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (header != null && header!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              context.trArgs('助动词: {0}', [header]),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: Inflection.personKeys.map((person) {
              final value = persons[person] ?? '';
              final label = Inflection.personLabels[person] ?? person;
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label ',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 变格卡片：单值行（第二格 / 复数 / 比较级 / 最高级 / 单人称回退）
///
/// 与 AI 查词界面 / 单词详情页共用，保证两处展示样式一致
class InflectionRow extends StatelessWidget {
  final String label;
  final String value;

  const InflectionRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
