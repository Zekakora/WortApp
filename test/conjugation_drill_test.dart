import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/conjugation_provider.dart';

void main() {
  group('PracticeMode 二级模式定义', () {
    test('包含全部 8 个二级子项', () {
      expect(PracticeMode.allVerbModes, hasLength(4));
      expect(PracticeMode.allNounModes, hasLength(3));
      expect(PracticeMode.allAdjModes, hasLength(1));
      expect(PracticeMode.allModes, hasLength(8));
    });

    test('动词时态模式标记 isVerbTense', () {
      for (final mode in PracticeMode.allVerbModes) {
        expect(mode.isVerbTense, isTrue, reason: '${mode.id} 应为 6 人称模式');
      }
      for (final mode in [...PracticeMode.allNounModes, ...PracticeMode.allAdjModes]) {
        expect(mode.isVerbTense, isFalse, reason: '${mode.id} 不应为 6 人称模式');
      }
    });

    test('fromId 可以反查模式', () {
      expect(PracticeMode.fromId('verb_praesens'), PracticeMode.verbPraesens);
      expect(PracticeMode.fromId('noun_genitiv'), PracticeMode.nounGenitiv);
      expect(PracticeMode.fromId('adj_steigerung'), PracticeMode.adjSteigerung);
      expect(PracticeMode.fromId('unknown'), isNull);
    });
  });

  group('答案校验', () {
    test('忽略大小写与多余空白', () {
      expect(ConjugationDrillNotifier.checkAnswer('  GEHT ', 'geht'), isTrue);
      expect(ConjugationDrillNotifier.checkAnswer('geht', 'Geht'), isTrue);
      expect(ConjugationDrillNotifier.checkAnswer('gehst', 'geht'), isFalse);
    });

    test('人称前缀容错（Perfekt 完整句）', () {
      // 标准答案不带人称，用户带了
      expect(ConjugationDrillNotifier.checkAnswer('ich habe gemacht', 'habe gemacht'), isTrue);
      // 标准答案带人称，用户只填了动词部分
      expect(ConjugationDrillNotifier.checkAnswer('habe gemacht', 'ich habe gemacht'), isTrue);
    });

    test('空答案判错', () {
      expect(ConjugationDrillNotifier.checkAnswer('', 'geht'), isFalse);
      expect(ConjugationDrillNotifier.checkAnswer('   ', 'geht'), isFalse);
    });
  });

  group('checkFields 高亮校验', () {
    final question = ConjugationQuestion(
      wordId: 1,
      word: 'gehen',
      mode: PracticeMode.verbPraesens,
      prompt: 'test',
      fields: const [
        PracticeField(label: 'ich', correctAnswer: 'gehe'),
        PracticeField(label: 'du', correctAnswer: 'gehst'),
        PracticeField(label: 'er/sie/es', correctAnswer: 'geht'),
        PracticeField(label: 'wir', correctAnswer: 'gehen'),
        PracticeField(label: 'ihr', correctAnswer: 'geht'),
        PracticeField(label: 'sie/Sie', correctAnswer: 'gehen'),
      ],
    );

    test('全部正确', () {
      final results = ConjugationDrillNotifier.checkFields(question, {
        'ich': 'gehe',
        'du': 'gehst',
        'er/sie/es': 'geht',
        'wir': 'gehen',
        'ihr': 'geht',
        'sie/Sie': 'gehen',
      });
      expect(results.values.every((r) => r.isCorrect), isTrue);
      expect(results.values.every((r) => !r.isBlank), isTrue);
    });

    test('拼写错误与漏填分别标记', () {
      final results = ConjugationDrillNotifier.checkFields(question, {
        'ich': 'gehe',
        'du': 'gehstX', // 拼写错误
        'er/sie/es': '', // 漏填
        'wir': 'gehen',
        'ihr': 'geht',
        'sie/Sie': 'gehen',
      });
      expect(results['ich']!.isCorrect, isTrue);
      expect(results['du']!.isCorrect, isFalse);
      expect(results['du']!.isBlank, isFalse);
      expect(results['er/sie/es']!.isCorrect, isFalse);
      expect(results['er/sie/es']!.isBlank, isTrue);
    });
  });

  group('抽题逻辑 loadDrill', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.deckDao.createDeck(DecksCompanion.insert(
        name: '测试词书',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
    });

    tearDown(() async {
      await db.close();
    });

    Future<Word> addWord({
      required String german,
      required String wordType,
      String? article,
      String? nounPlural,
      String? nounGenitive,
      String? adjComparative,
      String? adjSuperlative,
    }) async {
      final id = await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: german,
        chinese: '中文释义',
        wordType: drift.Value(wordType),
        article: drift.Value(article),
        nounPlural: drift.Value(nounPlural),
        nounGenitive: drift.Value(nounGenitive),
        adjComparative: drift.Value(adjComparative),
        adjSuperlative: drift.Value(adjSuperlative),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      return (await db.wordDao.getWordById(id))!;
    }

    test('动词现在时：无缓存时不出题', () async {
      await addWord(german: 'gehen', wordType: 'verb');
      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.verbPraesens, limit: 10);
      expect(notifier.state.questions, isEmpty);
    });

    test('动词现在时：有完整缓存时生成 6 人称题目', () async {
      final word = await addWord(german: 'gehen', wordType: 'verb');
      await db.conjugationDao.upsert(word.id, '''
      {
        "type": "verb",
        "praesens": {
          "ich": "gehe", "du": "gehst", "er_sie_es": "geht",
          "wir": "gehen", "ihr": "geht", "sie_Sie": "gehen"
        }
      }
      ''');

      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.verbPraesens, limit: 10);

      expect(notifier.state.questions, hasLength(1));
      final q = notifier.state.questions.first;
      expect(q.fields, hasLength(6));
      expect(q.fields.map((f) => f.label).toList(),
          ['ich', 'du', 'er/sie/es', 'wir', 'ihr', 'sie/Sie']);
      expect(q.fields.first.correctAnswer, 'gehe');
    });

    test('动词缓存缺少人称时跳过该单词', () async {
      final word = await addWord(german: 'gehen', wordType: 'verb');
      await db.conjugationDao.upsert(word.id, '''
      {
        "type": "verb",
        "praesens": {"ich": "gehe", "du": "gehst"}
      }
      ''');

      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.verbPraesens, limit: 10);
      expect(notifier.state.questions, isEmpty);
    });

    test('被动语态：由 werden + Partizip II 推导', () async {
      final word = await addWord(german: 'machen', wordType: 'verb');
      await db.conjugationDao.upsert(word.id, '''
      {
        "type": "verb",
        "perfekt": {
          "auxiliary": "haben",
          "partizip": "gemacht",
          "ich": "habe gemacht", "du": "hast gemacht", "er_sie_es": "hat gemacht",
          "wir": "haben gemacht", "ihr": "habt gemacht", "sie_Sie": "haben gemacht"
        }
      }
      ''');

      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.verbPassiv, limit: 10);

      expect(notifier.state.questions, hasLength(1));
      final q = notifier.state.questions.first;
      expect(q.fields.first.correctAnswer, 'werde gemacht');
      expect(q.fields[1].correctAnswer, 'wirst gemacht');
      expect(q.fields[2].correctAnswer, 'wird gemacht');
      expect(q.fields[3].correctAnswer, 'werden gemacht');
      expect(q.fields[4].correctAnswer, 'werdet gemacht');
      expect(q.fields[5].correctAnswer, 'werden gemacht');
    });

    test('名词冠词：从单词字段出题', () async {
      await addWord(german: 'Haus', wordType: 'noun', article: 'das');
      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.nounArticle, limit: 10);
      expect(notifier.state.questions, hasLength(1));
      expect(notifier.state.questions.first.fields.first.correctAnswer, 'das');
    });

    test('名词题目不携带 article，避免泄露定冠词答案', () async {
      await addWord(german: 'Haus', wordType: 'noun', article: 'das');
      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.nounArticle, limit: 10);
      expect(notifier.state.questions.first.article, isNull);

      final genitiv = ConjugationDrillNotifier(db);
      await genitiv.loadDrill(
          deckId: 1, mode: PracticeMode.nounGenitiv, limit: 10);
      expect(genitiv.state.questions, isEmpty); // 无二格数据不出题

      await addWord(german: 'Buch', wordType: 'noun', article: 'das', nounPlural: 'Bücher');
      final plural = ConjugationDrillNotifier(db);
      await plural.loadDrill(
          deckId: 1, mode: PracticeMode.nounPlural, limit: 10);
      expect(plural.state.questions, hasLength(1));
      expect(plural.state.questions.first.article, isNull);
    });

    test('名词第二格/复数：优先使用缓存', () async {
      final word =
          await addWord(german: 'Haus', wordType: 'noun', nounPlural: 'Häuser');
      await db.conjugationDao.upsert(word.id, '''
      {"type": "noun", "article": "das", "genitiv": "des Hauses", "plural": "Häuser"}
      ''');

      final genitiv = ConjugationDrillNotifier(db);
      await genitiv.loadDrill(deckId: 1, mode: PracticeMode.nounGenitiv, limit: 10);
      expect(genitiv.state.questions, hasLength(1));
      expect(genitiv.state.questions.first.fields.first.correctAnswer,
          'des Hauses');

      final plural = ConjugationDrillNotifier(db);
      await plural.loadDrill(deckId: 1, mode: PracticeMode.nounPlural, limit: 10);
      expect(plural.state.questions, hasLength(1));
      expect(plural.state.questions.first.fields.first.correctAnswer, 'Häuser');
    });

    test('形容词变级：比较级与最高级一页同时出题', () async {
      await addWord(
        german: 'schnell',
        wordType: 'adjective',
        adjComparative: 'schneller',
        adjSuperlative: 'am schnellsten',
      );

      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.adjSteigerung, limit: 10);

      expect(notifier.state.questions, hasLength(1));
      final q = notifier.state.questions.first;
      expect(q.fields, hasLength(2));
      expect(q.fields.map((f) => f.label).toList(), ['比较级', '最高级']);
      expect(q.fields[0].correctAnswer, 'schneller');
      expect(q.fields[1].correctAnswer, 'am schnellsten');
    });

    test('形容词变级：缺比较级或最高级时跳过该单词', () async {
      // 只有比较级，没有最高级
      await addWord(
        german: 'gut',
        wordType: 'adjective',
        adjComparative: 'besser',
      );
      // 只有最高级，没有比较级
      await addWord(
        german: 'schön',
        wordType: 'adjective',
        adjSuperlative: 'am schönsten',
      );

      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.adjSteigerung, limit: 10);
      expect(notifier.state.questions, isEmpty);
    });

    test('形容词变级：优先使用缓存中的比较级/最高级', () async {
      final word = await addWord(
        german: 'schnell',
        wordType: 'adjective',
        adjComparative: 'schneller',
        adjSuperlative: 'am schnellsten',
      );
      await db.conjugationDao.upsert(word.id, '''
      {"type": "adjective", "komparativ": "schneller", "superlativ": "am schnellsten"}
      ''');

      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.adjSteigerung, limit: 10);

      expect(notifier.state.questions, hasLength(1));
      final q = notifier.state.questions.first;
      expect(q.fields[0].correctAnswer, 'schneller');
      expect(q.fields[1].correctAnswer, 'am schnellsten');
    });

    test('limit 控制抽题数量', () async {
      for (var i = 0; i < 5; i++) {
        final word = await addWord(german: 'gehen$i', wordType: 'verb');
        await db.conjugationDao.upsert(word.id, '''
        {
          "type": "verb",
          "praesens": {
            "ich": "gehe", "du": "gehst", "er_sie_es": "geht",
            "wir": "gehen", "ihr": "geht", "sie_Sie": "gehen"
          }
        }
        ''');
      }
      final notifier = ConjugationDrillNotifier(db);
      await notifier.loadDrill(
          deckId: 1, mode: PracticeMode.verbPraesens, limit: 3);
      expect(notifier.state.questions, hasLength(3));
    });
  });

  group('答题状态流转', () {
    test('提交统计与完成状态', () {
      final question = ConjugationQuestion(
        wordId: 1,
        word: 'gehen',
        mode: PracticeMode.verbPraesens,
        prompt: 'test',
        fields: const [PracticeField(label: 'ich', correctAnswer: 'gehe')],
      );

      final notifier = ConjugationDrillNotifier(null);
      notifier.loadDrillSync(question, question);

      // 第 1 题：全对
      notifier.submitAnswer(isCorrect: true);
      expect(notifier.state.answeredCount, 1);
      expect(notifier.state.correctCount, 1);
      expect(notifier.state.isCompleted, isFalse);
      expect(notifier.state.progress, 0.5);

      // 第 2 题：错误
      notifier.submitAnswer(isCorrect: false);
      expect(notifier.state.answeredCount, 2);
      expect(notifier.state.correctCount, 1);
      expect(notifier.state.accuracy, 0.5);
      expect(notifier.state.progress, 1.0);
      expect(notifier.state.isCompleted, isFalse);

      // 进入下一题（第 2 题）
      notifier.next();
      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.isCompleted, isFalse);

      // 再进入下一题（全部完成）
      notifier.next();
      expect(notifier.state.currentIndex, 2);
      expect(notifier.state.isCompleted, isTrue);

      // 重置
      notifier.reset();
      expect(notifier.state.questions, isEmpty);
      expect(notifier.state.isCompleted, isFalse);
    });
  });
}

/// 测试辅助：直接注入题目列表（不经过数据库）
extension on ConjugationDrillNotifier {
  void loadDrillSync(ConjugationQuestion q1, ConjugationQuestion q2) {
    state = ConjugationDrillState(mode: PracticeMode.verbPraesens, questions: [q1, q2]);
  }
}
