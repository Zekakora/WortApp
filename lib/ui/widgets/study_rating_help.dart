import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/i18n/app_localizations.dart';

/// 打开「评分说明」对话框。
///
/// 讲解「忘记 / 模糊 / 熟悉 / 简单」四个评分按钮对 SM-2 间隔重复的影响，
/// 并给出常见情况（如“知道词义但忘记冠词/词性”）的推荐选择，帮助用户
/// 更好地发挥算法效果。
Future<void> showStudyRatingHelp(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _StudyRatingHelpDialog(),
  );
}

/// 学习页 AppBar 通用「评分说明」入口按钮。
class StudyRatingHelpButton extends StatelessWidget {
  const StudyRatingHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: context.tr('评分说明'),
      onPressed: () => showStudyRatingHelp(context),
    );
  }
}

class _StudyRatingHelpDialog extends StatelessWidget {
  const _StudyRatingHelpDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lightbulb_outline),
          const SizedBox(width: 8),
          Text(context.tr('评分说明')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(
                    '评分决定这个词下次什么时候再出现。如实评分最有利于长期记忆——为了心软给高分，词会很快消失、又很快忘。'),
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('四个按钮'),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const _RatingRow(
                color: ScoreColors.forgot,
                label: '忘记',
                desc: '完全想不起来 / 答错 → 明天再复习，重复进度清零',
              ),
              const _RatingRow(
                color: ScoreColors.hard,
                label: '模糊',
                desc: '有印象但没答对或答不全 → 明天再复习，进度保留、难度略升',
              ),
              const _RatingRow(
                color: ScoreColors.good,
                label: '熟悉',
                desc: '答对了，稍有停顿 → 按正常节奏延长复习间隔',
              ),
              const _RatingRow(
                color: ScoreColors.easy,
                label: '简单',
                desc: '秒答、毫不费力 → 间隔延长更多（要少用）',
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('常见情况怎么选'),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const _Bullet('靠排除法或运气猜对 → 选「模糊」，不要给熟悉/简单'),
              const _Bullet('拼写错但能认出、听音听不出 → 选「模糊」'),
              const _Bullet(
                '知道词义，但忘了冠词/词性（der·die·das）/复数/变位 → 选「模糊」',
              ),
              const _Bullet('基本都答对，只是略慢 → 选「熟悉」'),
              const _Bullet('一眼就会、毫不费力 → 选「简单」'),
              const SizedBox(height: 16),
              Text(
                context.tr(
                    '小贴士：德语名词建议把冠词一起记牢再给「熟悉」；答错（忘记/模糊）会进入错词重考并计入错误统计。'),
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('知道了')),
        ),
      ],
    );
  }
}

/// 单条评分按钮说明：彩色圆点 + 按钮名 + 效果
class _RatingRow extends StatelessWidget {
  final Color color;
  final String label;
  final String desc;

  const _RatingRow({
    required this.color,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(
            width: 44,
            child: Text(
              context.tr(label),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(context.tr(desc), style: textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// 场景条目（• 开头）
class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(context.tr(text))),
        ],
      ),
    );
  }
}
