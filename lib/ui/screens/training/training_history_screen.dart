import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../data/models/training.dart';
import '../../../ui/utils/wide_layout.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/training_provider.dart';
import 'exercise_player_screen.dart';
import 'exercise_result_screen.dart';

/// 练习历史（只存在本地，不参与备份与 OneDrive 同步）
class TrainingHistoryScreen extends ConsumerStatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  ConsumerState<TrainingHistoryScreen> createState() =>
      _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends ConsumerState<TrainingHistoryScreen> {
  TrainingSkill? _filter;
  List<ExerciseHistoryEntry> _unfinished = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUnfinished());
  }

  Future<void> _loadUnfinished() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    final rows = await db.exerciseDao.getUnfinished();
    if (!mounted) return;
    setState(() => _unfinished = rows);
  }

  Future<void> _delete(ExerciseHistoryEntry entry) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('删除这条练习记录？')),
        content: Text(dialogContext.tr('删除后无法恢复，相关题目与答案记录会一并删除。')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('删除')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await db.exerciseDao.deleteExercise(entry.id);
    ref.invalidate(trainingHistoryProvider);
    await _loadUnfinished();
  }

  Future<void> _clearAll() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('清空练习历史？')),
        content: Text(dialogContext.tr('将删除全部练习记录、题目与答案（不影响词书与 SM-2 复习数据）。')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('清空')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await db.exerciseDao.deleteAll();
    ref.invalidate(trainingHistoryProvider);
    await _loadUnfinished();
  }

  @override
  Widget build(BuildContext context) {
    final asyncHistory = ref.watch(trainingHistoryProvider(_filter));
    final entries = asyncHistory.valueOrNull ?? const <ExerciseHistoryEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('练习历史')),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clearAll();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'clear', child: Text(context.tr('清空练习历史'))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.tr('全部')),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final skill in TrainingSkill.values)
                  ChoiceChip(
                    label: Text(
                      '${skill.germanName} · ${context.tr(skill.titleZh)}',
                    ),
                    selected: _filter == skill,
                    onSelected: (_) => setState(() => _filter = skill),
                  ),
              ],
            ),
          ),
          Expanded(
            child: asyncHistory.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text(context.trArgs('读取历史失败: {0}', [error]))),
              data: (_) => Center(
                child: SizedBox(
                  // 宽屏限宽：一行文字过长反而难读，列表居中即可
                  width: WideLayout.isWide(context) ? 960 : double.infinity,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (_unfinished.isNotEmpty) ...[
                        Text(
                          context.tr('未完成的练习'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        for (final entry in _unfinished)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.play_circle_outline),
                              title: Text(
                                context.tr(entry.exerciseType.titleZh),
                              ),
                              subtitle: Text(
                                '${entry.level.code} · '
                                '${context.tr(entry.difficulty.titleZh)} · '
                                '${_formatDate(entry.createdAt)}',
                              ),
                              trailing: FilledButton.tonal(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ExercisePlayerScreen(
                                        exerciseId: entry.id,
                                      ),
                                    ),
                                  );
                                  ref.invalidate(trainingHistoryProvider);
                                  await _loadUnfinished();
                                },
                                child: Text(context.tr('继续')),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              context.tr('还没有练习记录'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )
                      else
                        for (final entry in entries)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: _scoreBadge(context, entry),
                              title: Text(
                                context.tr(entry.exerciseType.titleZh),
                              ),
                              subtitle: Text(
                                '${entry.level.code} · '
                                '${context.tr(entry.difficulty.titleZh)}'
                                '${entry.topic.isEmpty ? '' : ' · ${context.tr(entry.topic)}'}'
                                ' · ${_formatDate(entry.submittedAt ?? entry.createdAt)}',
                              ),
                              trailing: IconButton(
                                tooltip: context.tr('删除'),
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(entry),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExerciseResultScreen(
                                    exerciseId: entry.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _scoreBadge(BuildContext context, ExerciseHistoryEntry entry) {
    final percent = (entry.ratio * 100).round();
    final color = percent >= 80
        ? Colors.green
        : percent >= 50
        ? Colors.orange
        : Theme.of(context).colorScheme.error;
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        '$percent',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
