/// 练习生成器：调用现有 AI 服务生成结构化练习，并做解析 / 校验 / 有限重试
/// （任务书 §4.1 生命周期 3–5 步）
///
/// 分层约定：
/// - 这里**不碰 UI**，只返回结果或可读错误；
/// - 生成成功立刻落库（先保存题目，再进入答题页），网络异常不会丢失已生成内容；
/// - 生成失败也留一条 failed 记录（不进入历史列表），便于排查质量与失败率。
library;

import 'package:flutter/foundation.dart';

import '../../core/i18n/app_localizations.dart';
import '../../data/database/daos/exercise_dao.dart';
import '../../data/models/training.dart';
import '../ai/ai_service.dart';
import 'ai_json.dart';
import 'exercise_prompts.dart';
import 'exercise_schema.dart';

/// 一次生成请求参数
class ExerciseGenerationRequest {
  final ExerciseType type;
  final CefrLevel level;
  final TrainingDifficulty difficulty;

  /// 主题（中文名；为空表示随机）
  final String topic;
  final int questionCount;

  /// 可选词汇范围（收藏 / 指定词书里的德语词，逗号分隔）
  final String? vocabularyFocus;

  const ExerciseGenerationRequest({
    required this.type,
    required this.level,
    required this.difficulty,
    required this.topic,
    required this.questionCount,
    this.vocabularyFocus,
  });
}

/// 生成结果
class ExerciseGenerationResult {
  final int? exerciseId;
  final GeneratedExercise? exercise;

  /// 失败原因（可直接展示）
  final String? error;

  /// 非致命提示（例如"答案引用了不存在的选项已丢弃"）
  final List<String> warnings;

  const ExerciseGenerationResult({
    this.exerciseId,
    this.exercise,
    this.error,
    this.warnings = const [],
  });

  bool get ok => exercise != null && exerciseId != null;
}

/// 练习生成器
class ExerciseGenerator {
  final AIService aiService;
  final ExerciseDao dao;
  final String aiModel;

  ExerciseGenerator({
    required this.aiService,
    required this.dao,
    this.aiModel = '',
  });

  /// 生成并落库
  Future<ExerciseGenerationResult> generate(
    ExerciseGenerationRequest request,
  ) async {
    final prompt = ExercisePrompts.build(
      type: request.type,
      level: request.level,
      difficulty: request.difficulty,
      topic: request.topic,
      questionCount: request.questionCount,
      vocabularyFocus: request.vocabularyFocus,
    );
    final maxTokens = ExercisePrompts.maxTokensFor(
      request.questionCount,
      request.type,
    );

    // 两次尝试：第一次开 JSON 模式（部分厂商不支持会直接报错），
    // 第二次降级为普通请求 + 更低温度 + 明确"只返回 JSON"。
    final attempts = <_Attempt>[
      _Attempt(jsonMode: true, temperature: 0.35, maxTokens: maxTokens),
      _Attempt(jsonMode: false, temperature: 0.15, maxTokens: maxTokens),
    ];

    var lastError = AppLocale.tr('生成失败');
    final warnings = <String>[];

    for (var index = 0; index < attempts.length; index++) {
      final attempt = attempts[index];
      final isLast = index == attempts.length - 1;
      try {
        final raw = await aiService.chat(
          systemPrompt: prompt.systemPrompt,
          userMessage: index == 0
              ? prompt.userMessage
              : '${prompt.userMessage}\n\n上一次输出无法解析。请严格只返回一个 JSON 对象，'
                    '不要任何解释文字或代码块。',
          temperature: attempt.temperature,
          maxTokens: attempt.maxTokens,
          jsonMode: attempt.jsonMode,
          timeout: const Duration(seconds: 180),
        );

        final decoded = decodeJsonObject(raw);
        if (decoded == null) {
          lastError = AppLocale.tr('AI 返回的内容不是有效 JSON');
          debugPrint('训练生成：JSON 解析失败（第 ${index + 1} 次）');
          if (isLast) break;
          continue;
        }

        final parsed = ExerciseSchema.parse(
          decoded,
          expectedType: request.type,
          expectedLevel: request.level,
          expectedDifficulty: request.difficulty,
          expectedTopic: request.topic,
          minQuestions: request.questionCount,
        );

        if (!parsed.ok) {
          lastError = parsed.errorSummary.isEmpty
              ? AppLocale.tr('生成内容不符合格式要求')
              : parsed.errorSummary;
          debugPrint('训练生成：校验失败 ${parsed.issues}');
          if (isLast) break;
          continue;
        }

        warnings
          ..clear()
          ..addAll(parsed.issues.where((i) => !i.fatal).map((i) => i.message));

        final exercise = parsed.exercise!;
        final exerciseId = await dao.saveExercise(
          exercise,
          promptVersion: ExercisePrompts.version,
          aiModel: aiModel,
        );

        return ExerciseGenerationResult(
          exerciseId: exerciseId,
          exercise: exercise,
          warnings: warnings,
        );
      } on AIServiceException catch (e) {
        lastError = e.message;
        debugPrint('训练生成：AI 请求失败 ${e.message}');
        // JSON 模式被厂商拒绝时值得再试一次；其他网络错误直接给出结果
        if (isLast) break;
      } catch (e) {
        lastError = AppLocale.trArgs('生成失败: {0}', [e]);
        debugPrint('训练生成异常: $e');
        if (isLast) break;
      }
    }

    // 记录失败（保留排查信息），但返回给上层的仍是可读错误
    try {
      await dao.saveFailure(
        type: request.type,
        level: request.level,
        difficulty: request.difficulty,
        topic: request.topic,
        message: lastError,
        promptVersion: ExercisePrompts.version,
        aiModel: aiModel,
      );
    } catch (e) {
      debugPrint('记录生成失败时出错: $e');
    }

    return ExerciseGenerationResult(error: lastError);
  }
}

class _Attempt {
  final bool jsonMode;
  final double temperature;
  final int maxTokens;

  const _Attempt({
    required this.jsonMode,
    required this.temperature,
    required this.maxTokens,
  });
}
