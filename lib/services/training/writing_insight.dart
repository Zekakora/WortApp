/// 写作知识点统计
///
/// 只统计**写作类**练习（听力/阅读的客观题对错不进这里），
/// 数据来源是 AI 评分时写进 `exercise_attempts.feedback_json` 的 corrections：
/// 每条纠正带一个 [WritingKnowledge] 标签，这里按标签聚合次数与最近一次例子。
library;

import 'dart:convert';

import '../../data/database/daos/exercise_dao.dart';
import '../../data/models/writing_knowledge.dart';

/// 单个知识点的统计
class KnowledgePointStat {
  final WritingKnowledge knowledge;

  /// 该知识点被指出的次数
  final int count;

  /// 最近一次的例子（原文 / 建议 / 原因）
  final String? lastOriginal;
  final String? lastSuggestion;
  final String? lastReason;
  final DateTime? lastSeen;

  const KnowledgePointStat({
    required this.knowledge,
    required this.count,
    this.lastOriginal,
    this.lastSuggestion,
    this.lastReason,
    this.lastSeen,
  });
}

/// 写作知识点总览
class WritingKnowledgeInsight {
  /// 参与的写作练习次数（去重后的练习数）
  final int exerciseCount;

  /// 参与的写作作答次数
  final int attemptCount;

  /// 被指出的纠正总条数
  final int correctionCount;

  /// 按次数降序
  final List<KnowledgePointStat> points;

  const WritingKnowledgeInsight({
    this.exerciseCount = 0,
    this.attemptCount = 0,
    this.correctionCount = 0,
    this.points = const [],
  });

  bool get isEmpty => points.isEmpty;

  static const empty = WritingKnowledgeInsight();
}

/// 聚合写作答题记录
WritingKnowledgeInsight buildWritingKnowledgeInsight(
  List<WritingAttemptRow> rows,
) {
  if (rows.isEmpty) return WritingKnowledgeInsight.empty;

  final counts = <WritingKnowledge, int>{};
  final latest = <WritingKnowledge, DateTime>{};
  final examples = <WritingKnowledge, Map<String, String>>{};
  var correctionCount = 0;
  final exerciseIds = <int>{};

  for (final row in rows) {
    exerciseIds.add(row.exerciseId);
    final raw = row.attempt.feedbackJson;
    if (raw == null || raw.isEmpty) continue;

    final Map<String, dynamic> feedback;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      feedback = Map<String, dynamic>.from(decoded);
    } catch (_) {
      continue;
    }

    final corrections = feedback['corrections'];
    if (corrections is! List) continue;

    for (final item in corrections.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final knowledge = WritingKnowledge.fromCode(
        map['knowledge']?.toString() ?? '',
      );
      counts[knowledge] = (counts[knowledge] ?? 0) + 1;
      correctionCount++;

      final seenAt = row.createdAt;
      final previous = latest[knowledge];
      if (previous == null || seenAt.isAfter(previous)) {
        latest[knowledge] = seenAt;
        examples[knowledge] = {
          'original': map['original']?.toString() ?? '',
          'suggestion': map['suggestion']?.toString() ?? '',
          'reason': map['reason']?.toString() ?? '',
        };
      }
    }
  }

  final points = counts.entries.map((entry) {
    final example = examples[entry.key] ?? const <String, String>{};
    return KnowledgePointStat(
      knowledge: entry.key,
      count: entry.value,
      lastOriginal: example['original']?.isEmpty ?? true
          ? null
          : example['original'],
      lastSuggestion: example['suggestion']?.isEmpty ?? true
          ? null
          : example['suggestion'],
      lastReason: example['reason']?.isEmpty ?? true ? null : example['reason'],
      lastSeen: latest[entry.key],
    );
  }).toList()..sort((a, b) => b.count.compareTo(a.count));

  return WritingKnowledgeInsight(
    exerciseCount: exerciseIds.length,
    attemptCount: rows.length,
    correctionCount: correctionCount,
    points: points,
  );
}
