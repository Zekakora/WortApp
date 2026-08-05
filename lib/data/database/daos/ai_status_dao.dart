import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ai_request_status.dart';

part 'ai_status_dao.g.dart';

/// 请求状态常量
class AiRequestStatusValue {
  static const String success = 'success';
  static const String failed = 'failed';
}

@DriftAccessor(tables: [AiRequestStatus])
class AiStatusDao extends DatabaseAccessor<AppDatabase>
    with _$AiStatusDaoMixin {
  AiStatusDao(super.db);

  /// 获取单词最近的 AI 请求状态
  Future<AiRequestStatusData?> getStatus(String word,
      {String engine = 'ai'}) async {
    return (select(aiRequestStatus)
          ..where((t) => t.word.equals(word) & t.engine.equals(engine))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 批量获取单词列表的 AI 请求状态（word → 状态）
  Future<Map<String, AiRequestStatusData>> getStatusForWords(
    List<String> words, {
    String engine = 'ai',
  }) async {
    if (words.isEmpty) return {};
    final rows = await (select(aiRequestStatus)
          ..where((t) => t.word.isIn(words) & t.engine.equals(engine)))
        .get();
    return {for (final row in rows) row.word: row};
  }

  /// 记录 AI 请求结果（成功/失败），upsert 覆盖最近一次状态
  Future<void> record({
    required String word,
    required bool success,
    String? error,
    String engine = 'ai',
  }) async {
    final now = DateTime.now();
    await into(aiRequestStatus).insert(
      AiRequestStatusCompanion.insert(
        word: word,
        engine: Value(engine),
        status: success
            ? AiRequestStatusValue.success
            : AiRequestStatusValue.failed,
        errorMessage: Value(error),
        lastRequestAt: now,
      ),
      onConflict: DoUpdate(
        (old) => AiRequestStatusCompanion(
          status: Value(success ? AiRequestStatusValue.success : AiRequestStatusValue.failed),
          errorMessage: Value(error),
          lastRequestAt: Value(now),
        ),
        // 冲突目标为 (word, engine) 唯一键
        target: [aiRequestStatus.word, aiRequestStatus.engine],
      ),
    );
  }

  /// 删除状态记录
  Future<void> deleteStatus(String word, {String engine = 'ai'}) async {
    await (delete(aiRequestStatus)
          ..where((t) => t.word.equals(word) & t.engine.equals(engine)))
        .go();
  }

  /// 清空所有状态记录
  Future<void> clearAll() async {
    await delete(aiRequestStatus).go();
  }

  /// 判断缓存的 AI 结果 JSON 是否包含有效释义
  ///
  /// 用于「数据管理」检测单词是否已有 AI 释义（兼容旧版本未记录状态、仅存缓存的数据）
  static bool hasValidAiDefinitions(String resultJson) {
    try {
      final data = jsonDecode(resultJson);
      if (data is! Map<String, dynamic>) return false;
      final definitions = data['definitions'];
      if (definitions is! List) return false;
      return definitions.any((d) => d.toString().trim().isNotEmpty);
    } catch (_) {
      return false;
    }
  }
}
