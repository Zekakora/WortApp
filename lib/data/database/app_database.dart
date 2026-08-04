import 'package:drift/drift.dart';

import 'tables/decks.dart';
import 'tables/words.dart';
import 'tables/sm2_states.dart';
import 'tables/conjugation_cache.dart';
import 'tables/ai_lookup_cache.dart';
import 'tables/settings.dart';
import 'daos/deck_dao.dart';
import 'daos/word_dao.dart';
import 'daos/sm2_dao.dart';
import 'daos/conjugation_dao.dart';
import 'daos/ai_cache_dao.dart';

import 'app_database_native.dart'
    if (dart.library.html) 'app_database_web.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Decks, Words, Sm2States, ConjugationCache, AiLookupCache, Settings],
  daos: [DeckDao, WordDao, Sm2Dao, ConjugationDao, AiCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? impl.openConnection());

  @override
  int get schemaVersion => 2;

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
}
