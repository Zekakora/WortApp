import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';

void main() {
  group('复制单词到词书', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final now = DateTime(2026, 1, 1);
      await db.deckDao.createDeck(DecksCompanion.insert(
        name: '词书A',
        createdAt: now,
        updatedAt: now,
      ));
      await db.deckDao.createDeck(DecksCompanion.insert(
        name: '词书B',
        createdAt: now,
        updatedAt: now,
      ));
    });

    tearDown(() async {
      await db.close();
    });

    test('复制全部字段、变位缓存与 SM2 学习状态', () async {
      final wordId = await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'der Apfel',
        article: const drift.Value('der'),
        baseForm: const drift.Value('der Apfel'),
        wordType: const drift.Value('noun'),
        chinese: '苹果',
        example: const drift.Value('Der Apfel ist rot.'),
        tags: const drift.Value('水果'),
        nounGenitive: const drift.Value('des Apfels'),
        nounPlural: const drift.Value('Äpfel'),
        nounType: const drift.Value('countable'),
        proficiency: const drift.Value(3),
        lastStudyDate: drift.Value(DateTime(2026, 1, 5)),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await db.conjugationDao.upsert(
        wordId,
        '{"type":"noun","genitiv":"des Apfels","plural":"Äpfel"}',
      );
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: wordId,
        repetitionN: const drift.Value(2),
        intervalDays: const drift.Value(5),
        easeFactor: const drift.Value(2.2),
        nextReview: DateTime(2026, 1, 20),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 10),
      ));

      final newId = await db.copyWordToDeck(wordId, 2);
      expect(newId, isNotNull);

      final copy = await db.wordDao.getWordById(newId!);
      expect(copy, isNotNull);
      expect(copy!.deckId, 2);
      expect(copy.german, 'der Apfel');
      expect(copy.article, 'der');
      expect(copy.baseForm, 'der Apfel');
      expect(copy.wordType, 'noun');
      expect(copy.chinese, '苹果');
      expect(copy.example, 'Der Apfel ist rot.');
      expect(copy.tags, '水果');
      expect(copy.nounGenitive, 'des Apfels');
      expect(copy.nounPlural, 'Äpfel');
      expect(copy.nounType, 'countable');
      expect(copy.proficiency, 3);
      expect(copy.lastStudyDate, DateTime(2026, 1, 5));

      // 变位缓存已复制
      final conj = await db.conjugationDao.getByWordId(newId);
      expect(conj, isNotNull);
      expect(conj!.conjugationJson, contains('Äpfel'));

      // SM-2 学习状态已复制
      final sm2 = await db.sm2Dao.getStateByWordId(newId);
      expect(sm2, isNotNull);
      expect(sm2!.repetitionN, 2);
      expect(sm2.intervalDays, 5.0);
      expect(sm2.nextReview, DateTime(2026, 1, 20));

      // 原单词未被改动
      final original = await db.wordDao.getWordById(wordId);
      expect(original!.deckId, 1);
    });

    test('目标词书已有相同单词时返回 null', () async {
      final now = DateTime(2026, 1, 1);
      await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'laufen',
        chinese: '跑',
        createdAt: now,
        updatedAt: now,
      ));
      await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 2,
        german: 'laufen',
        chinese: '跑',
        createdAt: now,
        updatedAt: now,
      ));

      final wordInDeckA = await db.wordDao.findWordByGerman(1, 'laufen');
      expect(wordInDeckA, isNotNull);

      final newId = await db.copyWordToDeck(wordInDeckA!.id, 2);
      expect(newId, isNull);

      // 两个词书中仍各只有一条记录
      expect(await db.wordDao.getWordsByDeck(1), hasLength(1));
      expect(await db.wordDao.getWordsByDeck(2), hasLength(1));
    });
  });
}
