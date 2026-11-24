/// AI 训练模块的状态层（生成 / 答题会话 / 历史 / 记住上次设置）
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/exercise_dao.dart';
import '../data/models/training.dart';
import '../services/ai/ai_service.dart';
import '../services/speech/speech_playback_service.dart';
import '../services/training/exercise_generator.dart';
import '../services/training/grading_service.dart';
import 'database_provider.dart';
import 'deck_provider.dart';
import 'settings_provider.dart';

/// 训练语音播放服务（单例，随 Provider 生命周期释放）
final trainingSpeechProvider = Provider<SpeechPlaybackService>((ref) {
  final service = SpeechPlaybackService();
  ref.onDispose(service.dispose);
  return service;
});

/// 训练模块使用的 AI 服务（复用设置里的 AI 配置；未配置时为 null）
final trainingAiServiceProvider = Provider<AIService?>((ref) {
  final config = ref.watch(settingsProvider).aiConfig;
  if (!config.isConfigured) return null;
  return ConfigurableAIService(
    apiKey: config.apiKey,
    baseUrl: config.baseUrl,
    model: config.model,
  );
});

/// 练习生成器（数据库或 AI 配置缺失时为 null）
final trainingGeneratorProvider = Provider<ExerciseGenerator?>((ref) {
  final db = ref.watch(databaseProvider);
  final ai = ref.watch(trainingAiServiceProvider);
  if (db == null || ai == null) return null;
  return ExerciseGenerator(
    aiService: ai,
    dao: db.exerciseDao,
    aiModel: ref.watch(settingsProvider).aiConfig.model,
  );
});

/// 批改服务（AI 未配置时仍可批改客观题）
final trainingGradingProvider = Provider<GradingService>((ref) {
  return GradingService(aiService: ref.watch(trainingAiServiceProvider));
});

/// 训练设置记忆（等级 / 难度 / 题量 / 主题）
class TrainingPrefs {
  final CefrLevel level;
  final TrainingDifficulty difficulty;
  final int questionCount;
  final String topic;

  /// 是否优先使用收藏词汇（与等级、难度等选项一起记忆）
  final bool useFavorites;

  /// 是否已从数据库读取完成
  ///
  /// 设置是异步读取的，界面必须先等它加载完再初始化选项，
  /// 否则会先显示默认值（B1 / 普通 / 5 题）然后跳变成上次的选择。
  final bool isLoaded;

  const TrainingPrefs({
    this.level = CefrLevel.b1,
    this.difficulty = TrainingDifficulty.normal,
    this.questionCount = 5,
    this.topic = '',
    this.useFavorites = false,
    this.isLoaded = false,
  });

  TrainingPrefs copyWith({
    CefrLevel? level,
    TrainingDifficulty? difficulty,
    int? questionCount,
    String? topic,
    bool? useFavorites,
    bool? isLoaded,
  }) => TrainingPrefs(
    level: level ?? this.level,
    difficulty: difficulty ?? this.difficulty,
    questionCount: questionCount ?? this.questionCount,
    topic: topic ?? this.topic,
    useFavorites: useFavorites ?? this.useFavorites,
    isLoaded: isLoaded ?? this.isLoaded,
  );
}

/// 训练设置 Notifier：读写 settings 表（与其它设置一致，用 key/value 存储）
class TrainingPrefsNotifier extends StateNotifier<TrainingPrefs> {
  final AppDatabase? _db;

  TrainingPrefsNotifier(this._db) : super(const TrainingPrefs()) {
    _load();
  }

  Future<void> _load() async {
    final db = _db;
    if (db == null) {
      state = state.copyWith(isLoaded: true);
      return;
    }
    try {
      final level = await db.getSetting('training_level');
      final difficulty = await db.getSetting('training_difficulty');
      final count = await db.getSetting('training_count');
      final topic = await db.getSetting('training_topic');
      final useFavorites = await db.getSetting('training_use_favorites');

      final parsedCount = int.tryParse(count ?? '');
      state = TrainingPrefs(
        level: level == null ? state.level : CefrLevel.fromCode(level),
        difficulty: difficulty == null
            ? state.difficulty
            : TrainingDifficulty.fromCode(difficulty),
        questionCount: trainingQuestionCounts.contains(parsedCount)
            ? parsedCount!
            : state.questionCount,
        topic: topic ?? state.topic,
        useFavorites: useFavorites == 'true',
        isLoaded: true,
      );
    } catch (e) {
      debugPrint('读取训练设置失败: $e');
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> save(TrainingPrefs prefs) async {
    state = prefs.copyWith(isLoaded: true);
    final db = _db;
    if (db == null) return;
    try {
      await db.setSetting('training_level', prefs.level.code);
      await db.setSetting('training_difficulty', prefs.difficulty.code);
      await db.setSetting('training_count', prefs.questionCount.toString());
      await db.setSetting('training_topic', prefs.topic);
      await db.setSetting(
        'training_use_favorites',
        prefs.useFavorites.toString(),
      );
    } catch (e) {
      debugPrint('保存训练设置失败: $e');
    }
  }
}

final trainingPrefsProvider =
    StateNotifierProvider<TrainingPrefsNotifier, TrainingPrefs>((ref) {
      return TrainingPrefsNotifier(ref.watch(databaseProvider));
    });

/// 练习中「查词 / 收藏」的默认目标词书
///
/// 由「词书」页的菜单设置（`practice_default_deck_id`）。设置后，
/// 练习里收藏的词若还不在任何词书里，会自动加入这本词书（任务书 §6.2
/// 要求"用户主动确认才写库"，这里的"确认"就是点收藏这个动作）。
class PracticeDefaultDeckNotifier extends StateNotifier<int?> {
  final AppDatabase? _db;

  PracticeDefaultDeckNotifier(this._db) : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _db?.getSetting('practice_default_deck_id');
      final id = int.tryParse(raw ?? '');
      if (id != null) state = id;
    } catch (e) {
      debugPrint('读取练习默认词书失败: $e');
    }
  }

  /// 设置/清除默认词书（传 null 表示清除）
  Future<void> setDeck(int? deckId) async {
    state = deckId;
    try {
      if (deckId == null) {
        await _db?.deleteSetting('practice_default_deck_id');
      } else {
        await _db?.setSetting('practice_default_deck_id', deckId.toString());
      }
    } catch (e) {
      debugPrint('保存练习默认词书失败: $e');
    }
  }
}

final practiceDefaultDeckProvider =
    StateNotifierProvider<PracticeDefaultDeckNotifier, int?>((ref) {
      return PracticeDefaultDeckNotifier(ref.watch(databaseProvider));
    });

/// 练习历史（按技能筛选；练习历史只存本地，不参与备份与同步）
final trainingHistoryProvider =
    FutureProvider.family<List<ExerciseHistoryEntry>, TrainingSkill?>((
      ref,
      skill,
    ) async {
      final db = ref.watch(databaseProvider);
      if (db == null) return const [];
      return db.exerciseDao.getHistory(skill: skill);
    });

/// 收藏词汇（作为可选词汇范围传给生成提示词）
final favoriteVocabularyProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return const [];
  final deck = await ref.watch(activeDeckProvider.future);
  if (deck == null) return const [];
  final words = await db.wordDao.getWordsByDeck(deck.id);
  return words
      .where((w) => w.isFavorite)
      .map((w) => w.german)
      .take(40)
      .toList();
});

/// 答题会话状态
class TrainingSessionState {
  /// 已加载的练习（答题阶段数据，不含答案）
  final ExercisePlayback? playback;

  /// 题目 key → 用户答案（编码见 GradingService.grade）
  final Map<String, String> answers;

  final int currentIndex;

  /// 生成中 / 提交中
  final bool isBusy;

  /// 可读错误（生成失败等）
  final String? error;

  /// 非致命提示（校验告警、部分题目评分不可用等）
  final List<String> notices;

  /// 提交完成后的练习 id（用于跳转结果页）
  final int? submittedExerciseId;

  final DateTime? startedAt;

  const TrainingSessionState({
    this.playback,
    this.answers = const {},
    this.currentIndex = 0,
    this.isBusy = false,
    this.error,
    this.notices = const [],
    this.submittedExerciseId,
    this.startedAt,
  });

  bool get hasExercise => playback != null;

  int get total => playback?.questions.length ?? 0;

  bool get isLast => total > 0 && currentIndex >= total - 1;

  double get answeredRatio {
    if (total == 0) return 0;
    final answered = playback!.questions
        .where((q) => (answers[q.key] ?? '').trim().isNotEmpty)
        .length;
    return answered / total;
  }

  PlaybackQuestion? get currentQuestion {
    final list = playback?.questions;
    if (list == null || list.isEmpty) return null;
    final index = currentIndex.clamp(0, list.length - 1);
    return list[index];
  }

  TrainingSessionState copyWith({
    ExercisePlayback? playback,
    Map<String, String>? answers,
    int? currentIndex,
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<String>? notices,
    int? submittedExerciseId,
    bool clearSubmitted = false,
    DateTime? startedAt,
  }) => TrainingSessionState(
    playback: playback ?? this.playback,
    answers: answers ?? this.answers,
    currentIndex: currentIndex ?? this.currentIndex,
    isBusy: isBusy ?? this.isBusy,
    error: clearError ? null : (error ?? this.error),
    notices: notices ?? this.notices,
    submittedExerciseId: clearSubmitted
        ? null
        : (submittedExerciseId ?? this.submittedExerciseId),
    startedAt: startedAt ?? this.startedAt,
  );
}

/// 答题会话 Notifier
class TrainingSessionNotifier extends StateNotifier<TrainingSessionState> {
  final AppDatabase? _db;
  final ExerciseGenerator? _generator;
  final GradingService _grading;

  TrainingSessionNotifier(this._db, this._generator, this._grading)
    : super(const TrainingSessionState());

  ExerciseDao? get _dao => _db?.exerciseDao;

  static String _draftKey(int exerciseId) => 'training_draft_$exerciseId';

  /// 生成新练习并进入答题
  Future<int?> start(ExerciseGenerationRequest request) async {
    final generator = _generator;
    final dao = _dao;
    if (generator == null || dao == null) {
      state = state.copyWith(
        error: '请先在设置中配置 AI API Key，并确认数据库已就绪',
        isBusy: false,
      );
      return null;
    }

    state = state.copyWith(isBusy: true, clearError: true, notices: const []);
    try {
      final result = await generator.generate(request);
      if (!result.ok) {
        state = state.copyWith(isBusy: false, error: result.error);
        return null;
      }

      final playback = await dao.getPlayback(result.exerciseId!);
      if (playback == null) {
        state = state.copyWith(isBusy: false, error: '生成的练习读取失败');
        return null;
      }

      state = TrainingSessionState(
        playback: playback,
        answers: const {},
        currentIndex: 0,
        isBusy: false,
        notices: result.warnings,
        startedAt: DateTime.now(),
      );
      return result.exerciseId;
    } catch (e) {
      debugPrint('生成练习失败: $e');
      state = state.copyWith(isBusy: false, error: '生成失败: $e');
      return null;
    }
  }

  /// 从历史 / 未完成的练习继续作答（会恢复上次保存的草稿）
  Future<void> load(int exerciseId) async {
    final dao = _dao;
    if (dao == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    final playback = await dao.getPlayback(exerciseId);
    final answers = await _readDraft(exerciseId);
    state = TrainingSessionState(
      playback: playback,
      answers: answers,
      isBusy: false,
      error: playback == null ? '练习不存在或已被删除' : null,
      startedAt: DateTime.now(),
    );
  }

  /// 保存草稿（未提交的答案），退出时由答题页调用
  Future<void> saveDraft() async {
    final db = _db;
    final playback = state.playback;
    if (db == null || playback == null) return;
    if (state.answers.isEmpty) return;
    try {
      await db.setSetting(
        _draftKey(playback.exercise.id),
        jsonEncode(state.answers),
      );
    } catch (e) {
      debugPrint('保存训练草稿失败: $e');
    }
  }

  Future<Map<String, String>> _readDraft(int exerciseId) async {
    final db = _db;
    if (db == null) return const {};
    try {
      final raw = await db.getSetting(_draftKey(exerciseId));
      if (raw == null || raw.isEmpty) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries)
            entry.key.toString(): entry.value.toString(),
        };
      }
    } catch (e) {
      debugPrint('读取训练草稿失败: $e');
    }
    return const {};
  }

  Future<void> _clearDraft(int exerciseId) async {
    try {
      await _db?.deleteSetting(_draftKey(exerciseId));
    } catch (e) {
      debugPrint('清理训练草稿失败: $e');
    }
  }

  void setAnswer(String questionKey, String value) {
    final answers = Map<String, String>.from(state.answers);
    answers[questionKey] = value;
    state = state.copyWith(answers: answers);
  }

  void goTo(int index) {
    if (state.total == 0) return;
    state = state.copyWith(currentIndex: index.clamp(0, state.total - 1));
  }

  void next() => goTo(state.currentIndex + 1);

  void previous() => goTo(state.currentIndex - 1);

  void clearError() => state = state.copyWith(clearError: true);

  void reset() => state = const TrainingSessionState();

  /// 提交并批改，返回练习 id（失败返回 null）
  Future<int?> submit() async {
    final dao = _dao;
    final playback = state.playback;
    if (dao == null || playback == null) return null;

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final solutions = await dao.getSolutions(playback.exercise.id);
      final attempts = <AttemptInput>[];
      final notices = <String>[];
      var unavailable = 0;

      for (final question in playback.questions) {
        final solution = solutions[question.key];
        if (solution == null) continue;
        final userAnswer = state.answers[question.key] ?? '';
        final grade = await _grading.grade(
          question: question,
          solution: solution,
          userAnswer: userAnswer,
          level: CefrLevel.fromCode(playback.exercise.level),
          topic: playback.exercise.topic,
        );
        if (grade.graderType == 'unavailable') unavailable++;
        attempts.add(
          AttemptInput(
            questionKey: question.key,
            userAnswer: userAnswer,
            grade: grade,
          ),
        );
      }

      if (unavailable > 0) {
        notices.add('$unavailable 道题的评分暂不可用，已保留你的答案');
      }

      final duration = state.startedAt == null
          ? 0
          : DateTime.now().difference(state.startedAt!).inSeconds;

      await dao.saveSubmission(
        exerciseId: playback.exercise.id,
        attempts: attempts,
        durationSeconds: duration,
      );
      await _clearDraft(playback.exercise.id);

      state = state.copyWith(
        isBusy: false,
        submittedExerciseId: playback.exercise.id,
        notices: notices,
      );
      return playback.exercise.id;
    } catch (e) {
      debugPrint('提交失败: $e');
      state = state.copyWith(isBusy: false, error: '提交失败: $e');
      return null;
    }
  }
}

/// 答题会话 Provider
final trainingSessionProvider =
    StateNotifierProvider<TrainingSessionNotifier, TrainingSessionState>((ref) {
      final db = ref.watch(databaseProvider);
      return TrainingSessionNotifier(
        db,
        ref.watch(trainingGeneratorProvider),
        ref.watch(trainingGradingProvider),
      );
    });

/// 单个练习的结果数据（结果页用）
final trainingResultProvider = FutureProvider.family<ExerciseResultView?, int>((
  ref,
  exerciseId,
) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  return db.exerciseDao.getResultView(exerciseId);
});
