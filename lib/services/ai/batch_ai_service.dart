import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../dictionary/ai_dictionary_engine.dart';
import '../dictionary/dictionary_engine.dart';
import '../../data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

/// 批量AI更新进度
class BatchUpdateProgress {
  final int total;
  final int completed;
  final int failed;
  final String? currentWord;
  final bool isRunning;

  const BatchUpdateProgress({
    required this.total,
    required this.completed,
    required this.failed,
    this.currentWord,
    this.isRunning = false,
  });

  double get progress => total > 0 ? completed / total : 0;
  bool get isComplete => completed + failed >= total;
}

/// 批量AI更新服务
class BatchAIService {
  final AppDatabase _db;
  final AIDictionaryEngine _aiEngine;

  /// 并发查询数（同时进行的 AI 查询数量），默认 1 即逐个串行
  final int concurrency;

  BatchAIService(this._db, this._aiEngine, {this.concurrency = 1});

  /// 批量更新词书中缺少中文释义的单词
  Future<BatchUpdateProgress> updateWordsMeaning({
    required int deckId,
    bool overwrite = false,
    Function(BatchUpdateProgress)? onProgress,
  }) async {
    // 获取所有单词（如果overwrite为true则获取所有单词，否则只获取缺少中文释义的单词）
    final words = overwrite
        ? await _getAllWords(deckId)
        : await _getWordsNeedingUpdate(deckId);
    return _processWords(words, onProgress: onProgress, overwrite: overwrite);
  }

  /// 批量更新指定单词ID列表的词意（覆盖模式）
  Future<BatchUpdateProgress> updateWordsMeaningByIds({
    required List<int> wordIds,
    Function(BatchUpdateProgress)? onProgress,
  }) async {
    // 获取指定ID的单词
    final words = <Word>[];
    for (final id in wordIds) {
      final word = await (_db.select(_db.words)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (word != null) {
        words.add(word);
      }
    }
    return _processWords(words, onProgress: onProgress, overwrite: true);
  }

  /// 处理单词列表的通用方法
  ///
  /// 支持并发查询：按 [concurrency] 同时启动多个 worker，
  /// 每个 worker 依次领取待处理单词；串行（1）时保留请求间延迟避免限流。
  Future<BatchUpdateProgress> _processWords(
    List<Word> words, {
    Function(BatchUpdateProgress)? onProgress,
    bool overwrite = false,
  }) async {
    final total = words.length;

    if (total == 0) {
      return const BatchUpdateProgress(
        total: 0,
        completed: 0,
        failed: 0,
        isRunning: false,
      );
    }

    int completed = 0;
    int failed = 0;
    int nextIndex = 0;

    Future<void> processWord(Word word) async {
      try {
        // 更新进度
        onProgress?.call(BatchUpdateProgress(
          total: total,
          completed: completed,
          failed: failed,
          currentWord: word.german,
          isRunning: true,
        ));

        // 使用AI查询词意（forceRefresh=true 强制请求 AI，避免命中缓存旧结果）
        final result = await _aiEngine.lookup(word.german, forceRefresh: true);

        if (result != null) {
          // 更新单词信息
          await _updateWordFromResult(word.id, result, overwrite: overwrite);
          completed++;
        } else {
          failed++;
        }

        // 串行模式添加延迟避免API限流（并发模式由并发数控制请求压力）
        if (concurrency <= 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('Failed to update word ${word.german}: $e');
        failed++;
      }

      onProgress?.call(BatchUpdateProgress(
        total: total,
        completed: completed,
        failed: failed,
        currentWord: word.german,
        isRunning: true,
      ));
    }

    // 并发 worker 池：每个 worker 领取下一个未处理的单词，直到全部完成
    final workerCount = concurrency.clamp(1, 5);
    final workers = List.generate(workerCount, (_) async {
      while (true) {
        final index = nextIndex++;
        if (index >= words.length) break;
        await processWord(words[index]);
      }
    });
    await Future.wait(workers);

    // 最终进度
    final finalProgress = BatchUpdateProgress(
      total: total,
      completed: completed,
      failed: failed,
      isRunning: false,
    );

    onProgress?.call(finalProgress);
    return finalProgress;
  }

  /// 获取需要更新的单词列表（缺少中文释义的单词）
  Future<List<Word>> _getWordsNeedingUpdate(int deckId) async {
    return await (_db.select(_db.words)
          ..where((t) => t.deckId.equals(deckId))
          ..where((t) => t.chinese.equals('') | t.chinese.isNull()))
        .get();
  }

  /// 获取词书中的所有单词
  Future<List<Word>> _getAllWords(int deckId) async {
    return await (_db.select(_db.words)
          ..where((t) => t.deckId.equals(deckId)))
        .get();
  }

  /// 使用AI查询结果更新单词
  Future<void> _updateWordFromResult(int wordId, DictionaryResult result, {bool overwrite = false}) async {
    // 过滤空白字符串释义，避免把已有释义清空为空白
    final validDefinitions =
        result.definitions.where((d) => d.trim().isNotEmpty).toList();
    // AI 未返回有效释义时跳过更新，避免把已有释义清空为空白
    if (validDefinitions.isEmpty) {
      debugPrint('AI 未返回有效释义，跳过单词更新: id=$wordId');
      throw StateError('AI 未返回有效释义');
    }

    // 非覆盖模式下，单词已有释义则跳过
    if (!overwrite) {
      final current = await (_db.select(_db.words)
            ..where((t) => t.id.equals(wordId)))
          .getSingleOrNull();
      if (current != null && current.chinese.trim().isNotEmpty) {
        debugPrint('单词已有释义，跳过: ${current.german}');
        return;
      }
    }

    final infFields = Inflection.wordsFields(result);
    // 保护手动编辑（source='manual'）的变位数据：
    // 手动数据优先级高于 AI，批量更新时不覆盖 words 表变格字段与缓存
    final existingCache = await _db.conjugationDao.getByWordId(wordId);
    final hasManualInflection = existingCache?.source == 'manual';
    final companion = WordsCompanion(
      chinese: drift.Value(validDefinitions.first.trim()),
      article: result.article == null
          ? const drift.Value.absent()
          : drift.Value(result.article),
      baseForm: drift.Value(result.word),
      wordType: result.partOfSpeech == null
          ? const drift.Value.absent()
          : drift.Value(result.partOfSpeech),
      nounType: result.nounType == null
          ? const drift.Value.absent()
          : drift.Value(result.nounType),
      nounPlural: result.plural == null
          ? const drift.Value.absent()
          : drift.Value(result.plural),
      example: result.examples.isEmpty
          ? const drift.Value.absent()
          : drift.Value(result.examples.first),
      verbPresent: hasManualInflection || infFields['verbPresent'] == null
          ? const drift.Value.absent()
          : drift.Value(infFields['verbPresent']),
      verbPast: hasManualInflection || infFields['verbPast'] == null
          ? const drift.Value.absent()
          : drift.Value(infFields['verbPast']),
      verbPerfect: hasManualInflection || infFields['verbPerfect'] == null
          ? const drift.Value.absent()
          : drift.Value(infFields['verbPerfect']),
      nounGenitive: hasManualInflection || infFields['nounGenitive'] == null
          ? const drift.Value.absent()
          : drift.Value(infFields['nounGenitive']),
      adjComparative: hasManualInflection || infFields['adjComparative'] == null
          ? const drift.Value.absent()
          : drift.Value(infFields['adjComparative']),
      adjSuperlative: hasManualInflection || infFields['adjSuperlative'] == null
          ? const drift.Value.absent()
          : drift.Value(infFields['adjSuperlative']),
      updatedAt: drift.Value(DateTime.now()),
    );

    await (_db.update(_db.words)..where((t) => t.id.equals(wordId))).write(companion);

    // 变格数据写入 conjugation_cache，与变格练习打通；手动编辑数据不被覆盖
    final inflectionJson = result.normalizedInflection;
    if (!hasManualInflection &&
        inflectionJson != null &&
        !Inflection.isEmpty(inflectionJson)) {
      await _db.conjugationDao.upsert(wordId, jsonEncode(inflectionJson));
    }

    // 缓存AI结果到ai_lookup_cache表（与search_screen保持一致）
    try {
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
        'collocations': result.collocations?.map((c) => {
          'pattern': c.pattern,
          'case': c.caseType,
          'meaning': c.meaning,
        }).toList() ?? [],
        'noun_type': result.nounType,
        'inflection': result.normalizedInflection,
      });
      await _db.aiCacheDao.saveToCache(
        word: result.word,
        resultJson: cacheJson,
      );
    } catch (e) {
      debugPrint('缓存AI结果失败: $e');
    }
  }
}
