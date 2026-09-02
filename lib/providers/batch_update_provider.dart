import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai/batch_ai_service.dart';

/// 任务状态枚举
enum TaskStatus {
  queued,    // 排队中
  running,   // 运行中
  completed, // 已完成
  failed,    // 失败
}

/// 单个任务记录
class BatchTaskRecord {
  final String id;
  final String name;
  final TaskStatus status;
  final int total;
  final int completed;
  final int failed;
  final String? currentWord;
  final List<String> errors;
  final DateTime createdAt;
  final DateTime? completedAt;

  const BatchTaskRecord({
    required this.id,
    required this.name,
    required this.status,
    required this.total,
    required this.completed,
    required this.failed,
    this.currentWord,
    required this.errors,
    required this.createdAt,
    this.completedAt,
  });

  double get progress => total > 0 ? completed / total : 0;
  bool get isComplete => status == TaskStatus.completed || status == TaskStatus.failed;
  bool get isRunning => status == TaskStatus.running;
  bool get isQueued => status == TaskStatus.queued;

  BatchTaskRecord copyWith({
    TaskStatus? status,
    int? total,
    int? completed,
    int? failed,
    String? currentWord,
    List<String>? errors,
    DateTime? completedAt,
  }) {
    return BatchTaskRecord(
      id: id,
      name: name,
      status: status ?? this.status,
      total: total ?? this.total,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      currentWord: currentWord ?? this.currentWord,
      errors: errors ?? this.errors,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// 批量更新状态
class BatchUpdateState {
  final List<BatchTaskRecord> tasks;
  final BatchTaskRecord? currentTask;

  /// 排队中/运行中任务涉及的单词集合（去重），
  /// 用于详情页等界面检测单词是否已在 AI 查询队列中，避免重复触发 AI 查询浪费 token
  final Set<String> pendingWords;

  const BatchUpdateState({
    this.tasks = const [],
    this.currentTask,
    this.pendingWords = const {},
  });

  /// 单词是否已在 AI 查询队列中（排队中或运行中）
  bool isWordPending(String word) => pendingWords.contains(word);

  /// 是否有正在运行的任务
  bool get hasRunningTask => tasks.any((t) => t.isRunning || t.isQueued);

  /// 是否有任何任务记录
  bool get hasTasks => tasks.isNotEmpty;

  /// 运行中的任务数
  int get runningCount => tasks.where((t) => t.isRunning).length;

  /// 排队中的任务数
  int get queuedCount => tasks.where((t) => t.isQueued).length;

  /// 已完成的任务数
  int get completedCount => tasks.where((t) => t.isComplete).length;

  /// 总进度文本
  String get progressText {
    if (currentTask == null) return '无任务';
    return '${currentTask!.completed}/${currentTask!.total}';
  }

  /// 总错误数
  int get totalErrors => tasks.fold(0, (sum, t) => sum + t.errors.length);

  BatchUpdateState copyWith({
    List<BatchTaskRecord>? tasks,
    BatchTaskRecord? currentTask,
    Set<String>? pendingWords,
  }) {
    return BatchUpdateState(
      tasks: tasks ?? this.tasks,
      currentTask: currentTask ?? this.currentTask,
      pendingWords: pendingWords ?? this.pendingWords,
    );
  }
}

/// 批量更新 StateNotifier
class BatchUpdateNotifier extends StateNotifier<BatchUpdateState> {
  BatchUpdateNotifier() : super(const BatchUpdateState());

  int _taskCounter = 0;

  /// taskId → 任务包含的单词列表（用于任务结束时从 pendingWords 清理）
  final Map<String, List<String>> _taskWords = {};

  /// 单词是否已在 AI 查询队列中（排队中或运行中）
  bool isWordPending(String word) => state.pendingWords.contains(word);

  /// 添加新任务
  String addTask(String name, int total, {List<String>? words}) {
    final taskId = 'task_${++_taskCounter}';
    final task = BatchTaskRecord(
      id: taskId,
      name: name,
      status: TaskStatus.queued,
      total: total,
      completed: 0,
      failed: 0,
      errors: [],
      createdAt: DateTime.now(),
    );

    // 记录任务包含的单词，加入待处理集合
    final taskWords = (words ?? const <String>[])
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toSet()
        .toList();
    _taskWords[taskId] = taskWords;

    state = state.copyWith(
      tasks: [...state.tasks, task],
      currentTask: task,
      pendingWords: {...state.pendingWords, ...taskWords},
    );

    return taskId;
  }

  /// 开始执行任务
  void startTask(String taskId) {
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(status: TaskStatus.running);
      }
      return t;
    }).toList();

    final currentTask = updatedTasks.firstWhere((t) => t.id == taskId);

    state = state.copyWith(
      tasks: updatedTasks,
      currentTask: currentTask,
    );
  }

  /// 更新任务进度
  void updateProgress(String taskId, BatchUpdateProgress progress) {
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          status: TaskStatus.running,
          total: progress.total,
          completed: progress.completed,
          failed: progress.failed,
          currentWord: progress.currentWord,
        );
      }
      return t;
    }).toList();

    final currentTask = updatedTasks.firstWhere((t) => t.id == taskId);

    state = state.copyWith(
      tasks: updatedTasks,
      currentTask: currentTask,
    );
  }

  /// 添加错误
  void addError(String taskId, String error) {
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          errors: [...t.errors, error],
        );
      }
      return t;
    }).toList();

    state = state.copyWith(tasks: updatedTasks);
  }

  /// 完成任务
  void completeTask(String taskId, BatchUpdateProgress finalProgress) {
    final removedWords = _takeTaskWords(taskId);
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          status: TaskStatus.completed,
          total: finalProgress.total,
          completed: finalProgress.completed,
          failed: finalProgress.failed,
          currentWord: null,
          completedAt: DateTime.now(),
        );
      }
      return t;
    }).toList();

    // 查找下一个排队的任务；任务列表可能已被清空（用户点“清除全部”）
    final nextTask = updatedTasks.isEmpty
        ? null
        : updatedTasks.firstWhere(
            (t) => t.isQueued || t.isRunning,
            orElse: () => updatedTasks.last,
          );

    state = state.copyWith(
      tasks: updatedTasks,
      currentTask: nextTask == null || nextTask.isComplete ? null : nextTask,
      pendingWords: {...state.pendingWords}..removeAll(removedWords),
    );
  }

  /// 标记任务失败
  void failTask(String taskId, String error) {
    final removedWords = _takeTaskWords(taskId);
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          status: TaskStatus.failed,
          errors: [...t.errors, error],
          completedAt: DateTime.now(),
        );
      }
      return t;
    }).toList();

    state = state.copyWith(
      tasks: updatedTasks,
      pendingWords: {...state.pendingWords}..removeAll(removedWords),
    );
  }

  /// 清除所有任务
  void clearAll() {
    _taskWords.clear();
    state = const BatchUpdateState();
  }

  /// 清除已完成的任务
  void clearCompleted() {
    final removedIds = state.tasks.where((t) => t.isComplete).map((t) => t.id);
    final removedWords = <String>{};
    for (final id in removedIds) {
      removedWords.addAll(_takeTaskWords(id));
    }

    final remaining = state.tasks.where((t) => !t.isComplete).toList();
    state = state.copyWith(
      tasks: remaining,
      currentTask: remaining.isNotEmpty ? remaining.last : null,
      pendingWords: {...state.pendingWords}..removeAll(removedWords),
    );
  }

  /// 清除指定任务
  void removeTask(String taskId) {
    final removedWords = _takeTaskWords(taskId);
    final remaining = state.tasks.where((t) => t.id != taskId).toList();
    state = state.copyWith(
      tasks: remaining,
      currentTask: state.currentTask?.id == taskId
          ? (remaining.isNotEmpty ? remaining.last : null)
          : state.currentTask,
      pendingWords: {...state.pendingWords}..removeAll(removedWords),
    );
  }

  /// 取出并移除指定任务的单词记录，返回其单词列表
  List<String> _takeTaskWords(String taskId) {
    return _taskWords.remove(taskId) ?? const <String>[];
  }
}

/// 批量更新 Provider
final batchUpdateProvider =
    StateNotifierProvider<BatchUpdateNotifier, BatchUpdateState>((ref) {
  return BatchUpdateNotifier();
});
