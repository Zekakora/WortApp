import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/decks.dart';
import '../tables/words.dart';
import '../tables/sm2_states.dart';
import '../tables/conjugation_cache.dart';

part 'deck_dao.g.dart';

@DriftAccessor(tables: [Decks, Words, Sm2States, ConjugationCache])
class DeckDao extends DatabaseAccessor<AppDatabase> with _$DeckDaoMixin {
  DeckDao(super.db);

  /// 获取所有词书
  Future<List<Deck>> getAllDecks() => select(decks).get();

  /// 监听所有词书变化
  Stream<List<Deck>> watchAllDecks() => select(decks).watch();

  /// 获取当前激活词书
  Future<Deck?> getActiveDeck() async {
    return (select(decks)..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// 监听当前激活词书
  Stream<Deck?> watchActiveDeck() {
    return (select(decks)..where((t) => t.isActive.equals(true)))
        .watchSingleOrNull();
  }

  /// 根据 ID 获取词书
  Future<Deck?> getDeckById(int id) {
    return (select(decks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 创建词书
  Future<int> createDeck(DecksCompanion entry) {
    return into(decks).insert(entry);
  }

  /// 更新词书
  Future<bool> updateDeck(DecksCompanion entry) {
    return update(decks).replace(entry);
  }

  /// 删除词书及其所有关联数据（级联删除）
  Future<void> deleteDeck(int deckId) async {
    await transaction(() async {
      // 1. 删除该词书中所有单词的变位缓存
      // 注意：customStatement 的参数是原始值列表，不能传 Variable 对象（Web 端会报 Unknown db value）
      await customStatement(
        'DELETE FROM conjugation_cache WHERE word_id IN (SELECT id FROM words WHERE deck_id = ?)',
        [deckId],
      );
      // 2. 删除该词书中所有单词的 SM-2 状态
      await customStatement(
        'DELETE FROM sm2_states WHERE word_id IN (SELECT id FROM words WHERE deck_id = ?)',
        [deckId],
      );
      // 3. 删除该词书中所有单词
      await (delete(words)..where((t) => t.deckId.equals(deckId))).go();
      // 4. 删除词书本身
      await (delete(decks)..where((t) => t.id.equals(deckId))).go();
    });
  }

  /// 设置激活词书
  Future<void> setActiveDeck(int deckId) async {
    // 先取消所有激活状态
    await (update(decks)..where((t) => t.isActive.equals(true)))
        .write(const DecksCompanion(isActive: Value(false)));
    // 设置新的激活词书
    await (update(decks)..where((t) => t.id.equals(deckId)))
        .write(const DecksCompanion(isActive: Value(true)));
  }

  /// 获取词书数量
  Future<int> getDeckCount() async {
    final count = await customSelect(
      'SELECT COUNT(*) as cnt FROM decks',
      readsFrom: {decks},
    ).getSingle();
    return count.data['cnt'] as int;
  }
}
