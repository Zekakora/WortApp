import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

/// 当前激活词书 Provider
final activeDeckProvider = StreamProvider<Deck?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return const Stream.empty();
  return db.deckDao.watchActiveDeck();
});

/// 所有词书 Provider
final allDecksProvider = StreamProvider<List<Deck>>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return const Stream.empty();
  return db.deckDao.watchAllDecks();
});

/// 词书单词数量 Provider
final wordCountProvider = FutureProvider.family<int, int>((ref, deckId) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return 0;
  return db.wordDao.getWordCount(deckId);
});

/// 词书单词列表 Provider
final wordsByDeckProvider =
    StreamProvider.family<List<Word>, int>((ref, deckId) {
  final db = ref.watch(databaseProvider);
  if (db == null) return const Stream.empty();
  return db.wordDao.watchWordsByDeck(deckId);
});
