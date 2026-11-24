import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/database/app_database.dart';

/// 名词词性（定冠词 der/die/das）判定的共享工具
///
/// 学习模式的「额外一步选词性」与翻牌模式口径一致：
/// wordType 为 noun 或缺失时，只要带有 der/die/das 冠词，即视为需要作答的名词。
class NounArticle {
  NounArticle._();

  /// 三色选择器固定顺序（与翻牌模式一致）
  static const List<String> articles = ['die', 'das', 'der'];

  /// 是否为需要先作答定冠词的名词
  static bool isNounWithArticle(Word word) {
    final article = word.article;
    if (article == null) return false;
    final a = article.trim().toLowerCase();
    if (a != 'der' && a != 'die' && a != 'das') return false;
    return word.wordType == 'noun' || word.wordType == null;
  }

  /// 规范化冠词（小写去空格）
  static String? normalizedArticle(Word word) =>
      word.article?.trim().toLowerCase();

  /// 是否已答对该名词的定冠词
  static bool isAnswered(Word word, String? selectedArticle, int? selectedWordId) =>
      selectedWordId == word.id &&
      selectedArticle == normalizedArticle(word);
}

/// 定冠词三色选择器（die/das/der），配色与翻牌模式一致：
/// der 蓝 / die 红 / das 绿；答对后选中项填充实色并打勾。
///
/// 仅负责展示与回调，作答状态由各模式自行持有（便于切词失效与重置）。
class NounArticleSelector extends StatelessWidget {
  const NounArticleSelector({
    super.key,
    required this.selectedArticle,
    required this.answered,
    required this.onSelect,
    this.title = '请选择词性',
  });

  /// 当前选中的冠词（der/die/das），未选为 null
  final String? selectedArticle;

  /// 是否已答对；答对后选中项填充实色
  final bool answered;

  /// 点击某个冠词的回调
  final ValueChanged<String> onSelect;

  /// 顶部提示文案
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: NounArticle.articles.map((article) {
            final color = GenderColors.forArticle(article);
            final isSelected = selectedArticle == article;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(article),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected && answered
                        ? color
                        : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected && answered
                          ? color
                          : color.withValues(alpha: 0.45),
                      width: isSelected && answered ? 2 : 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        article,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected && answered ? Colors.white : color,
                        ),
                      ),
                      if (isSelected && answered) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
