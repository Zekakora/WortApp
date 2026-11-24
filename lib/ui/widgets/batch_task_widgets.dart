import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_localizations.dart';
import '../../providers/batch_update_provider.dart';

/// 后台AI任务进度按钮（带任务数角标）
///
/// 点击打开任务列表对话框；有运行中任务时图标高亮，有错误时角标变红。
class BatchTaskProgressButton extends ConsumerWidget {
  const BatchTaskProgressButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batchUpdateProvider);
    final hasActiveTask = state.hasRunningTask;
    final taskCount = state.tasks.length;
    final errorCount = state.totalErrors;

    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            color: hasActiveTask
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          if (taskCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: errorCount > 0
                      ? Theme.of(context).colorScheme.error
                      : hasActiveTask
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  '$taskCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: hasActiveTask
          ? context.tr('AI 任务进行中')
          : context.tr('AI 任务记录'),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => BatchTaskListDialog(
            onClearAll: () {
              ref.read(batchUpdateProvider.notifier).clearAll();
            },
            onClearCompleted: () {
              ref.read(batchUpdateProvider.notifier).clearCompleted();
            },
            onRemoveTask: (taskId) {
              ref.read(batchUpdateProvider.notifier).removeTask(taskId);
            },
          ),
        );
      },
    );
  }
}

/// 任务列表对话框（实时监听任务状态，后台运行时进度即时刷新）
class BatchTaskListDialog extends ConsumerWidget {
  final VoidCallback onClearAll;
  final VoidCallback onClearCompleted;
  final Function(String) onRemoveTask;

  const BatchTaskListDialog({
    super.key,
    required this.onClearAll,
    required this.onClearCompleted,
    required this.onRemoveTask,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batchUpdateProvider);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(context.tr('AI 任务列表'))),
          if (state.tasks.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'clear_completed':
                    onClearCompleted();
                    break;
                  case 'clear_all':
                    onClearAll();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear_completed',
                  child: Text(context.tr('清除已完成')),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Text(context.tr('清除全部')),
                ),
              ],
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: state.tasks.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(context.tr('暂无任务记录')),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                  final task = state.tasks.reversed.toList()[index];
                  return _TaskTile(
                    task: task,
                    onRemove: () => onRemoveTask(task.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('关闭')),
        ),
      ],
    );
  }
}

/// 任务项
class _TaskTile extends StatelessWidget {
  final BatchTaskRecord task;
  final VoidCallback onRemove;

  const _TaskTile({
    required this.task,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildStatusIcon(context),
        title: Text(
          task.name,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: _buildSubtitle(context),
        trailing: task.isComplete
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
                tooltip: context.tr('移除'),
              )
            : null,
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (task.status) {
      case TaskStatus.queued:
        return const Icon(Icons.queue, color: Colors.grey);
      case TaskStatus.running:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: task.progress,
            strokeWidth: 3,
          ),
        );
      case TaskStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case TaskStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  Widget? _buildSubtitle(BuildContext context) {
    if (task.isRunning) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: task.progress,
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            '${task.completed}/${task.total}${task.currentWord != null ? ' - ${task.currentWord}' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    } else if (task.isComplete) {
      final duration = task.completedAt?.difference(task.createdAt);
      final durationText = duration != null
          ? ' ${context.trArgs('（{0} 秒）', [duration.inSeconds])}'
          : '';
      return Text(
        context.trArgs(
          '完成: {0} 成功, {1} 失败{2}',
          [task.completed, task.failed, durationText],
        ),
        style: TextStyle(
          fontSize: 12,
          color: task.failed > 0 ? Colors.red : Colors.grey,
        ),
      );
    } else if (task.isQueued) {
      return Text(
        context.tr('排队中...'),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
    return null;
  }
}
