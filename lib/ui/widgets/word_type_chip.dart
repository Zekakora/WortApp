import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 词性标签组件
class WordTypeChip extends StatelessWidget {
  final String? wordType;
  final String? article;
  final bool showLabel;
  final bool compact;

  const WordTypeChip({
    super.key,
    this.wordType,
    this.article,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (wordType == null) return const SizedBox.shrink();

    final color = WordTypeColors.forWordType(wordType, article: article);
    final label = WordTypeColors.getWordTypeLabel(wordType);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              WordTypeColors.getWordTypeDescription(wordType),
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 名词可数/不可数标签
class NounTypeChip extends StatelessWidget {
  final String? nounType; // countable, uncountable, both

  const NounTypeChip({
    super.key,
    required this.nounType,
  });

  @override
  Widget build(BuildContext context) {
    if (nounType == null) return const SizedBox.shrink();

    Color color;
    String label;
    String description;

    switch (nounType) {
      case 'countable':
        color = Colors.blue;
        label = 'C';
        description = '可数';
        break;
      case 'uncountable':
        color = Colors.orange;
        label = 'U';
        description = '不可数';
        break;
      case 'both':
        color = Colors.purple;
        label = 'C/U';
        description = '可数/不可数';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
