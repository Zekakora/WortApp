import 'package:drift/drift.dart';

import '../../algorithms/sm2_algorithm.dart';
import '../../core/utils/german_parser.dart';
import 'tables/decks.dart';
import 'tables/words.dart';
import 'tables/sm2_states.dart';
import 'tables/conjugation_cache.dart';
import 'tables/ai_lookup_cache.dart';
import 'tables/ai_request_status.dart';
import 'tables/settings.dart';
import 'tables/study_stats.dart';
import 'tables/deletion_logs.dart';
import 'daos/deck_dao.dart';
import 'daos/word_dao.dart';
import 'daos/sm2_dao.dart';
import 'daos/conjugation_dao.dart';
import 'daos/ai_cache_dao.dart';
import 'daos/ai_status_dao.dart';
import 'daos/study_stat_dao.dart';

import 'app_database_native.dart'
    if (dart.library.html) 'app_database_web.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Decks,
    Words,
    Sm2States,
    ConjugationCache,
    AiLookupCache,
    AiRequestStatus,
    Settings,
    StudyStats,
    DeletionLogs,
  ],
  daos: [
    DeckDao,
    WordDao,
    Sm2Dao,
    ConjugationDao,
    AiCacheDao,
    AiStatusDao,
    StudyStatDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? impl.openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // 添加名词类型字段
            await m.addColumn(words, words.nounType);
          }
          if (from < 3) {
            // 新增 AI 请求状态表（数据管理用）
            await m.createTable(aiRequestStatus);
          }
          if (from < 4) {
            // 添加收藏标记字段 + 每日练习统计表（错误统计排行榜用）
            await m.addColumn(words, words.isFavorite);
            await m.createTable(studyStats);
          }
          if (from < 5) {
            // 删除墓碑表（跨端删除传播用）
            await m.createTable(deletionLogs);
          }
        },
      );

  /// 获取设置值
  Future<String?> getSetting(String key) async {
    final query = select(settings)..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  /// 设置值
  Future<void> setSetting(String key, String value) async {
    await into(settings).insert(
      SettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: DateTime.now(),
      ),
      onConflict: DoUpdate((old) => SettingsCompanion(
            value: Value(value),
            updatedAt: Value(DateTime.now()),
          )),
    );
  }

  /// 删除设置
  Future<void> deleteSetting(String key) async {
    await (delete(settings)..where((t) => t.key.equals(key))).go();
  }

  /// 提交一次学习反馈：更新 SM-2 复习状态并刷新单词上次学习日期（事务）
  ///
  /// [quality] 0-5 评分（见 [SM2Algorithm.calculate]）。首次学习创建状态，
  /// 否则更新现有状态（重复次数 / 复习间隔 / 简易度 / 连续正确等），
  /// 同时刷新 [words.lastStudyDate] 用于“今日已学”统计。
  Future<void> submitStudyFeedback({
    required int wordId,
    required int quality,
  }) {
    return transaction(() async {
      final now = DateTime.now();
      final sm2State = await sm2Dao.getStateByWordId(wordId);

      if (sm2State == null) {
        final result = SM2Algorithm.calculate(
          quality: quality,
          currentN: 0,
          currentInterval: 0,
          currentEF: 2.5,
        );
        await sm2Dao.createState(
          Sm2StatesCompanion(
            wordId: Value(wordId),
            repetitionN: Value(result.repetitionN),
            intervalDays: Value(result.intervalDays),
            easeFactor: Value(result.easeFactor),
            nextReview: Value(result.nextReview),
            lastReview: Value(now),
            totalReviews: const Value(1),
            correctStreak: Value(quality >= 3 ? 1 : 0),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      } else {
        final result = SM2Algorithm.calculate(
          quality: quality,
          currentN: sm2State.repetitionN,
          currentInterval: sm2State.intervalDays,
          currentEF: sm2State.easeFactor,
        );
        await sm2Dao.updateState(
          Sm2StatesCompanion(
            id: Value(sm2State.id),
            wordId: Value(wordId),
            repetitionN: Value(result.repetitionN),
            intervalDays: Value(result.intervalDays),
            easeFactor: Value(result.easeFactor),
            nextReview: Value(result.nextReview),
            lastReview: Value(now),
            totalReviews: Value(sm2State.totalReviews + 1),
            correctStreak: Value(
              quality >= 3 ? sm2State.correctStreak + 1 : 0,
            ),
            createdAt: Value(sm2State.createdAt),
            updatedAt: Value(now),
          ),
        );
      }

      await wordDao.updateLastStudyDate(wordId);
    });
  }

  /// 将单词复制到另一词书（同一单词允许在不同词书中同时存在，共享 AI 查词缓存）
  ///
  /// 复制内容包含：单词全部字段、变位缓存（conjugation_cache）与 SM-2 学习状态。
  /// 目标词书中已存在相同规范化词形的单词时返回 null（词书内不允许重复，
  /// `der Hund` 与 `Hund` 归为同一词）；
  /// 成功时返回新单词 ID。
  Future<int?> copyWordToDeck(int wordId, int targetDeckId) {
    return transaction(() async {
      final word = await wordDao.getWordById(wordId);
      if (word == null) return null;

      // 目标词书内查重（跨词书允许重复，同一词书内不允许）
      final existing = await wordDao.findWordByCanonicalKeyInDeck(
        targetDeckId,
        GermanParser.canonicalKey(word.german),
      );
      if (existing != null) return null;

      final now = DateTime.now();
      final newId = await wordDao.createWord(
        WordsCompanion(
          deckId: Value(targetDeckId),
          german: Value(word.german),
          article: word.article == null
              ? const Value.absent()
              : Value(word.article),
          baseForm: word.baseForm == null
              ? const Value.absent()
              : Value(word.baseForm),
          wordType: word.wordType == null
              ? const Value.absent()
              : Value(word.wordType),
          chinese: Value(word.chinese),
          example: word.example == null
              ? const Value.absent()
              : Value(word.example),
          tags: word.tags == null ? const Value.absent() : Value(word.tags),
          proficiency: Value(word.proficiency),
          isFavorite: Value(word.isFavorite),
          lastStudyDate: word.lastStudyDate == null
              ? const Value.absent()
              : Value(word.lastStudyDate),
          verbPresent: word.verbPresent == null
              ? const Value.absent()
              : Value(word.verbPresent),
          verbPast: word.verbPast == null
              ? const Value.absent()
              : Value(word.verbPast),
          verbPerfect: word.verbPerfect == null
              ? const Value.absent()
              : Value(word.verbPerfect),
          nounGenitive: word.nounGenitive == null
              ? const Value.absent()
              : Value(word.nounGenitive),
          nounPlural: word.nounPlural == null
              ? const Value.absent()
              : Value(word.nounPlural),
          nounType: word.nounType == null
              ? const Value.absent()
              : Value(word.nounType),
          adjComparative: word.adjComparative == null
              ? const Value.absent()
              : Value(word.adjComparative),
          adjSuperlative: word.adjSuperlative == null
              ? const Value.absent()
              : Value(word.adjSuperlative),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 复制变位缓存（与源单词共用同一份变位数据）
      final conj = await conjugationDao.getByWordId(wordId);
      if (conj != null) {
        await conjugationDao.upsert(
          newId,
          conj.conjugationJson,
          source: conj.source,
        );
      }

      // 复制 SM-2 学习状态（复制品继承复习进度）
      final sm2 = await sm2Dao.getStateByWordId(wordId);
      if (sm2 != null) {
        await sm2Dao.createState(
          Sm2StatesCompanion(
            wordId: Value(newId),
            repetitionN: Value(sm2.repetitionN),
            intervalDays: Value(sm2.intervalDays),
            easeFactor: Value(sm2.easeFactor),
            nextReview: Value(sm2.nextReview),
            lastReview: sm2.lastReview == null
                ? const Value.absent()
                : Value(sm2.lastReview),
            totalReviews: Value(sm2.totalReviews),
            correctStreak: Value(sm2.correctStreak),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      return newId;
    });
  }

  /// 记录一条删除墓碑（跨端删除传播用）
  ///
  /// [german] 为空字符串表示整词书删除。
  Future<void> logDeletion(
    String deckName,
    String german, {
    DateTime? deletedAt,
  }) async {
    await into(deletionLogs).insert(
      DeletionLogsCompanion.insert(
        deckName: deckName,
        german: Value(german),
        deletedAt: deletedAt ?? DateTime.now(),
      ),
    );
  }

  /// 读取全部删除墓碑（导出备份用）
  Future<List<DeletionLog>> getAllDeletions() {
    return (select(deletionLogs)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
  }

  /// 将墓碑表整体替换为同步合并后的墓碑集合（清空重写，幂等）
  Future<void> replaceAllDeletions(List<Map<String, dynamic>> deletions) async {
    await transaction(() async {
      await delete(deletionLogs).go();
      for (final d in deletions) {
        final deckName = d['deck']?.toString().trim() ?? '';
        if (deckName.isEmpty) continue;
        final german = d['german']?.toString() ?? '';
        final deletedAt = DateTime.tryParse(
          d['deletedAt']?.toString() ?? '',
        );
        await into(deletionLogs).insert(
          DeletionLogsCompanion.insert(
            deckName: deckName,
            german: Value(german),
            deletedAt: deletedAt ?? DateTime.now(),
          ),
        );
      }
    });
  }

  /// 删除单词并释放关联数据（事务）
  ///
  /// 同时记录删除墓碑（跨端删除传播）；并删除该单词的 SM-2 学习状态与变位缓存
  /// （wordId 级关联）；若删除后任何词书都不再存在相同德语单词（忽略大小写，
  /// 与词书内查重规则一致），则释放共享的 AI 查词缓存（ai_lookup_cache）与
  /// AI 请求状态记录（ai_request_status）。
  Future<void> deleteWordWithCleanup(int wordId) {
    return transaction(() async {
      final word = await wordDao.getWordById(wordId);
      if (word == null) return;

      // 记录删除墓碑（跨端删除传播：对端将据此删除同名词）
      final deck = await deckDao.getDeckById(word.deckId);
      if (deck != null) {
        await logDeletion(deck.name, word.german);
      }

      await deleteWordInternal(word);
    });
  }

  /// 实际删除单词（不写墓碑，供同步合并删除时内部调用）
  Future<void> deleteWordInternal(Word word) async {
    // 先删除 wordId 级关联数据，避免遗留孤儿记录
    await (delete(sm2States)..where((t) => t.wordId.equals(word.id))).go();
    await (delete(conjugationCache)..where((t) => t.wordId.equals(word.id)))
        .go();
    await (delete(studyStats)..where((t) => t.wordId.equals(word.id))).go();
    await wordDao.deleteWord(word.id);

    // 检查其他词书是否仍存在相同单词
    final stillExists = await (select(words)
          ..where(
              (t) => t.german.lower().equals(word.german.toLowerCase())))
        .getSingleOrNull();
    if (stillExists == null) {
      // 无其他词书引用，释放共享的 AI 缓存与请求状态
      await aiCacheDao.deleteCache(word.german);
      await aiStatusDao.deleteStatus(word.german);
    }
  }

  /// 扫描词书内重复单词：按规范化词形分组（`der Hund` 与 `Hund` 归为同一词，
  /// 德语大小写保留语义），返回包含 2 条及以上记录的重复组。
  Future<List<WordDedupGroup>> findDeckDuplicateGroups(int deckId) async {
    final words = await wordDao.getWordsByDeck(deckId);
    final byKey = <String, List<Word>>{};
    for (final w in words) {
      byKey
          .putIfAbsent(GermanParser.canonicalKey(w.german), () => [])
          .add(w);
    }
    final groups = <WordDedupGroup>[];
    byKey.forEach((key, ws) {
      if (ws.length > 1) {
        groups.add(WordDedupGroup(canonicalKey: key, words: ws));
      }
    });
    // 重复条数多的组排前
    groups.sort((a, b) => b.words.length.compareTo(a.words.length));
    return groups;
  }

  /// 合并一组重复单词：保留 [keepWordId]，将被删词的 SM-2 学习状态、每日
  /// 错误统计、变位缓存并入保留词后删除，返回被删除的单词 id 列表。
  ///
  /// 删除走 [deleteWordInternal]（不写墓碑）：同词仍保留在词书中，不会释放
  /// 共享的 AI 查词缓存。
  Future<List<int>> mergeDuplicateGroup({
    required int keepWordId,
    required List<int> removeWordIds,
  }) {
    return transaction(() async {
      final keep = await wordDao.getWordById(keepWordId);
      if (keep == null) return const [];

      final removed = <int>[];
      for (final removeId in removeWordIds) {
        if (removeId == keepWordId) continue;
        final dup = await wordDao.getWordById(removeId);
        if (dup == null) continue;

        // SM-2 状态：保留词无状态时继承被删词的状态（学习进度不丢失）
        final keepSm2 = await sm2Dao.getStateByWordId(keep.id);
        if (keepSm2 == null) {
          final dupSm2 = await sm2Dao.getStateByWordId(dup.id);
          if (dupSm2 != null) {
            await sm2Dao.createState(
              Sm2StatesCompanion(
                wordId: Value(keep.id),
                repetitionN: Value(dupSm2.repetitionN),
                intervalDays: Value(dupSm2.intervalDays),
                easeFactor: Value(dupSm2.easeFactor),
                nextReview: Value(dupSm2.nextReview),
                lastReview: dupSm2.lastReview == null
                    ? const Value.absent()
                    : Value(dupSm2.lastReview),
                totalReviews: Value(dupSm2.totalReviews),
                correctStreak: Value(dupSm2.correctStreak),
                createdAt: Value(dupSm2.createdAt),
                updatedAt: Value(dupSm2.updatedAt),
              ),
            );
          }
        }

        // 每日错误统计：按日期累加到保留词（不丢练习记录）
        final dupStats = await (select(studyStats)
              ..where((t) => t.wordId.equals(dup.id)))
            .get();
        for (final s in dupStats) {
          final keepRow = await (select(studyStats)
                ..where((t) =>
                    t.wordId.equals(keep.id) & t.date.equals(s.date)))
              .getSingleOrNull();
          if (keepRow == null) {
            await into(studyStats).insert(
              StudyStatsCompanion.insert(
                wordId: keep.id,
                date: s.date,
                appearances: Value(s.appearances),
                errors: Value(s.errors),
              ),
            );
          } else {
            await (update(studyStats)
                  ..where((t) => t.id.equals(keepRow.id)))
                .write(
              StudyStatsCompanion(
                appearances: Value(keepRow.appearances + s.appearances),
                errors: Value(keepRow.errors + s.errors),
              ),
            );
          }
        }

        // 变位缓存：保留词无缓存时继承
        final keepConj = await conjugationDao.getByWordId(keep.id);
        if (keepConj == null) {
          final dupConj = await conjugationDao.getByWordId(dup.id);
          if (dupConj != null) {
            await conjugationDao.upsert(
              keep.id,
              dupConj.conjugationJson,
              source: dupConj.source,
            );
          }
        }

        await deleteWordInternal(dup);
        removed.add(dup.id);
      }
      return removed;
    });
  }

  /// 重置所有单词的学习进度（事务）
  ///
  /// 清空全部 SM-2 复习状态（sm2_states 表）与错误统计（study_stats 表），
  /// 并将所有单词的熟练度（proficiency）归零、上次学习日期（lastStudyDate）
  /// 置空，所有单词变为“新词”状态。
  Future<void> resetAllLearningProgress() {
    return transaction(() async {
      await delete(sm2States).go();
      await delete(studyStats).go();
      await (update(words)).write(
        WordsCompanion(
          proficiency: const Value(0),
          lastStudyDate: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}

/// 词书内重复单词分组（按规范化词形）
class WordDedupGroup {
  /// 规范化词形（`der Hund` 与 `Hund` 都归为 `Hund`）
  final String canonicalKey;

  /// 该组内的重复记录（2 条及以上）
  final List<Word> words;

  const WordDedupGroup({required this.canonicalKey, required this.words});
}
