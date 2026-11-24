/// 查词结果入库服务
///
/// 从「联网查词」页面的私有方法提取出来的可复用逻辑，供训练模块的
/// 长按查词 Sheet 与查词页面共用，避免两条入库路径逐渐走偏。
///
/// 语义与原有实现保持一致（任务书 §6.2 要求复用、不重复建词、不重置 SM-2）：
/// - 全局按 `GermanParser.canonicalKey` 查重（`der Hund` 与 `Hund` 视为同一词）；
/// - 纯词典来源（Wiktionary / 德语助手）只写入单词本身，不写释义与变格；
/// - AI 结果同时补写 conjugation_cache 与 ai_lookup_cache；
/// - **不触碰** sm2_states：新词的 SM-2 状态由首次学习时按现有规则创建。
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/utils/german_parser.dart';
import '../../data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;

import 'dictionary_engine.dart';

/// 入库结果
enum WordIntakeStatus {
  /// 新增成功
  added,

  /// 已存在（任何词书中），未重复添加
  alreadyExists,

  /// 写入失败
  failed,
}

/// 入库结果详情
class WordIntakeResult {
  final WordIntakeStatus status;
  final Word? existingWord;
  final Deck? existingDeck;
  final String? error;

  const WordIntakeResult({
    required this.status,
    this.existingWord,
    this.existingDeck,
    this.error,
  });

  bool get isAdded => status == WordIntakeStatus.added;
}

/// 查词结果入库
class WordIntakeService {
  final AppDatabase db;

  WordIntakeService(this.db);

  /// 全局规范化查重
  Future<WordIntakeResult?> findExisting(DictionaryResult result) async {
    final key = GermanParser.canonicalKey(result.word);
    final existing = await db.wordDao.findWordByCanonicalKey(key);
    if (existing == null) return null;
    return WordIntakeResult(
      status: WordIntakeStatus.alreadyExists,
      existingWord: existing,
      existingDeck: await db.deckDao.getDeckById(existing.deckId),
    );
  }

  /// 把查词结果写入指定词书
  Future<WordIntakeResult> addToDeck({
    required int deckId,
    required DictionaryResult result,
  }) async {
    try {
      final existing = await findExisting(result);
      if (existing != null) return existing;

      final now = DateTime.now();

      if (result.wordOnly) {
        await db.wordDao.createWord(
          WordsCompanion(
            deckId: Value(deckId),
            german: Value(result.word),
            chinese: const Value(''),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        return const WordIntakeResult(status: WordIntakeStatus.added);
      }

      final infFields = Inflection.wordsFields(result);
      await db.wordDao.createWord(
        WordsCompanion(
          deckId: Value(deckId),
          german: Value(result.word),
          article: Value(result.article),
          baseForm: Value(result.word),
          wordType: Value(result.partOfSpeech),
          chinese: Value(
              result.definitions.isNotEmpty ? result.definitions.first : ''),
          example: Value(
              result.examples.isNotEmpty ? result.examples.first : null),
          nounType: Value(result.nounType),
          nounPlural: Value(result.plural),
          verbPresent: infFields['verbPresent'] == null
              ? const Value.absent()
              : Value(infFields['verbPresent']),
          verbPast: infFields['verbPast'] == null
              ? const Value.absent()
              : Value(infFields['verbPast']),
          verbPerfect: infFields['verbPerfect'] == null
              ? const Value.absent()
              : Value(infFields['verbPerfect']),
          nounGenitive: infFields['nounGenitive'] == null
              ? const Value.absent()
              : Value(infFields['nounGenitive']),
          adjComparative: infFields['adjComparative'] == null
              ? const Value.absent()
              : Value(infFields['adjComparative']),
          adjSuperlative: infFields['adjSuperlative'] == null
              ? const Value.absent()
              : Value(infFields['adjSuperlative']),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 变格数据写入 conjugation_cache，与变位练习打通
      final newWord = await db.wordDao.findWordByGerman(deckId, result.word);
      final inflectionJson = result.normalizedInflection;
      if (newWord != null &&
          inflectionJson != null &&
          !Inflection.isEmpty(inflectionJson)) {
        await db.conjugationDao.upsert(newWord.id, jsonEncode(inflectionJson));
      }

      await _ensureAiCache(result);

      return const WordIntakeResult(status: WordIntakeStatus.added);
    } catch (e) {
      debugPrint('加入词书失败: $e');
      return WordIntakeResult(
        status: WordIntakeStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// 确保 AI 查词结果在缓存里（查词时通常已缓存，这里兜底一次）
  Future<void> _ensureAiCache(DictionaryResult result) async {
    if (result.engine != 'AI 解析') return;
    try {
      final existingCache = await db.aiCacheDao.getCachedResult(result.word);
      if (existingCache != null) return;
      final cacheJson = jsonEncode({
        'word': result.word,
        'article': result.article ?? '',
        'plural': result.plural ?? '',
        'definitions': result.definitions,
        'examples': result.examples,
        'part_of_speech': result.partOfSpeech ?? '',
        'analysis': result.aiAnalysis ?? '',
        'verb_type': result.verbType,
        'conjugation': result.conjugation ?? {},
        'separable_prefix': result.separablePrefix,
        'base_verb': result.baseVerb,
        'collocations': result.collocations
                ?.map((c) => {
                      'pattern': c.pattern,
                      'case': c.caseType,
                      'meaning': c.meaning,
                    })
                .toList() ??
            [],
        'noun_type': result.nounType,
        'inflection': result.normalizedInflection,
      });
      await db.aiCacheDao.saveToCache(word: result.word, resultJson: cacheJson);
    } catch (e) {
      debugPrint('缓存保存失败: $e');
    }
  }
}
