import 'package:flutter/material.dart';
import '../../providers/batch_update_provider.dart';
import '../../services/ai/batch_ai_service.dart';

/// AI 批量更新词意进度对话框
///
/// 支持两种模式：
/// - [wordIds] 模式：批量更新指定单词（覆盖模式）
/// - [deckId] 模式：更新整个词书（[overwrite] 控制是否覆盖已有释义）
///
/// 关闭窗口后任务转入后台继续运行，可从页面右上角任务按钮查看进度。
class BatchUpdateDialog extends StatefulWidget {
  final BatchAIService batchService;
  final BatchUpdateNotifier notifier;

  /// 指定单词 ID 列表模式（与 deckId 模式互斥）
  final List<int>? wordIds;

  /// 单词德语文本（用于任务记录中的待处理集合，详情页据此避免重复查询）
  final List<String>? words;

  /// 整个词书模式（与 wordIds 模式互斥）
  final int? deckId;
  final bool overwrite;

  /// 任务显示名称
  final String taskName;

  const BatchUpdateDialog({
    super.key,
    required this.batchService,
    required this.notifier,
    this.wordIds,
    this.words,
    this.deckId,
    this.overwrite = false,
    this.taskName = 'AI 更新词意',
  });

  @override
  State<BatchUpdateDialog> createState() => _BatchUpdateDialogState();
}

class _BatchUpdateDialogState extends State<BatchUpdateDialog> {
  BatchUpdateProgress? _progress;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    // 延迟到widget树构建完成后启动，避免在构建期间修改provider状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startUpdate();
      }
    });
  }

  Future<void> _startUpdate() async {
    setState(() {
      _isStarted = true;
    });

    // 创建任务记录（携带单词列表，供详情页检测队列中的单词）
    final wordIds = widget.wordIds;
    final total = wordIds != null
        ? wordIds.length
        : 1; // deckId 模式初始为1，进度更新时替换为实际值
    final taskId = widget.notifier.addTask(
      widget.taskName,
      total,
      words: widget.words,
    );
    widget.notifier.startTask(taskId);

    try {
      final progress = wordIds != null
          ? await widget.batchService.updateWordsMeaningByIds(
              wordIds: wordIds,
              onProgress: (progress) {
                // 无论对话框是否关闭（含后台运行）都同步全局任务状态，
                // 保证任务列表/进度按钮实时更新；setState 仅限界面存活时
                widget.notifier.updateProgress(taskId, progress);
                if (mounted) {
                  setState(() {
                    _progress = progress;
                  });
                }
              },
            )
          : await widget.batchService.updateWordsMeaning(
              deckId: widget.deckId!,
              overwrite: widget.overwrite,
              onProgress: (progress) {
                widget.notifier.updateProgress(taskId, progress);
                if (mounted) {
                  setState(() {
                    _progress = progress;
                  });
                }
              },
            );

      // 同样不依赖 mounted：对话框关闭后任务仍在后台运行
      widget.notifier.completeTask(taskId, progress);
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    } catch (e) {
      widget.notifier.failTask(taskId, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return AlertDialog(
      title: Text(progress?.isComplete == true ? '更新完成' : 'AI 更新词意'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress == null || !_isStarted) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('准备中...'),
          ] else if (!progress.isComplete) ...[
            LinearProgressIndicator(value: progress.progress),
            const SizedBox(height: 16),
            Text('${progress.completed}/${progress.total}'),
            if (progress.currentWord != null) ...[
              const SizedBox(height: 8),
              Text(
                '正在处理: ${progress.currentWord}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '关闭窗口可后台运行',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ] else ...[
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text('成功更新: ${progress.completed} 个单词'),
            if (progress.failed > 0)
              Text('失败: ${progress.failed} 个单词',
                  style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        if (progress?.isComplete == true || !_isStarted)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('后台运行'),
          ),
      ],
    );
  }
}
