import 'package:drift/drift.dart';

import 'tables/decks.dart';
import 'tables/words.dart';
import 'tables/sm2_states.dart';
import 'tables/conjugation_cache.dart';
import 'tables/ai_lookup_cache.dart';
import 'tables/ai_request_status.dart';
import 'tables/settings.dart';
import 'tables/study_stats.dart';
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
  int get schemaVersion => 4;

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

  /// 将单词复制到另一词书（同一单词允许在不同词书中同时存在，共享 AI 查词缓存）
  ///
  /// 复制内容包含：单词全部字段、变位缓存（conjugation_cache）与 SM-2 学习状态。
  /// 目标词书中已存在相同德语单词时返回 null（词书内不允许重复）；
  /// 成功时返回新单词 ID。
  Future<int?> copyWordToDeck(int wordId, int targetDeckId) {
    return transaction(() async {
      final word = await wordDao.getWordById(wordId);
      if (word == null) return null;

      // 目标词书内查重（跨词书允许重复，同一词书内不允许）
      final existing = await wordDao.findWordByGerman(targetDeckId, word.german);
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

  /// 删除单词并释放关联数据（事务）
  ///
  /// 同时删除该单词的 SM-2 学习状态与变位缓存（wordId 级关联）；
  /// 若删除后任何词书都不再存在相同德语单词（忽略大小写，与词书内查重规则一致），
  /// 则释放共享的 AI 查词缓存（ai_lookup_cache）与 AI 请求状态记录（ai_request_status）。
  Future<void> deleteWordWithCleanup(int wordId) {
    return transaction(() async {
      final word = await wordDao.getWordById(wordId);
      if (word == null) return;

      // 先删除 wordId 级关联数据，避免遗留孤儿记录
      await (delete(sm2States)..where((t) => t.wordId.equals(wordId))).go();
      await (delete(conjugationCache)..where((t) => t.wordId.equals(wordId)))
          .go();
      await (delete(studyStats)..where((t) => t.wordId.equals(wordId))).go();
      await wordDao.deleteWord(wordId);

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
