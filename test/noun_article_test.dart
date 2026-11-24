import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/ui/widgets/noun_article_selector.dart';

Word makeWord({
  required int id,
  String? article,
  String? wordType,
  String german = 'Haus',
}) {
  final now = DateTime(2026, 1, 1);
  return Word(
    id: id,
    deckId: 1,
    german: german,
    article: article,
    wordType: wordType,
    chinese: '房子',
    proficiency: 0,
    isFavorite: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('NounArticle.isNounWithArticle', () {
    test('名词带 der/die/das 冠词需要先作答词性', () {
      expect(
        NounArticle.isNounWithArticle(
            makeWord(id: 1, article: 'der', wordType: 'noun')),
        isTrue,
      );
      expect(
        NounArticle.isNounWithArticle(
            makeWord(id: 2, article: 'die', wordType: 'noun')),
        isTrue,
      );
      expect(
        NounArticle.isNounWithArticle(
            makeWord(id: 3, article: 'das', wordType: 'noun')),
        isTrue,
      );
    });

    test('wordType 缺失但带冠词时按名词处理', () {
      expect(
        NounArticle.isNounWithArticle(makeWord(id: 4, article: 'das')),
        isTrue,
      );
    });

    test('冠词大小写与空格容错', () {
      expect(
        NounArticle.isNounWithArticle(
            makeWord(id: 5, article: ' Die ', wordType: 'noun')),
        isTrue,
      );
    });

    test('无冠词、非名词或非法冠词不触发', () {
      expect(
        NounArticle.isNounWithArticle(makeWord(id: 6, wordType: 'noun')),
        isFalse,
      );
      expect(
        NounArticle.isNounWithArticle(
            makeWord(id: 7, article: 'der', wordType: 'verb')),
        isFalse,
      );
      expect(
        NounArticle.isNounWithArticle(
            makeWord(id: 8, article: 'ein', wordType: 'noun')),
        isFalse,
      );
      expect(NounArticle.isNounWithArticle(makeWord(id: 9)), isFalse);
    });
  });

  group('NounArticle 作答判定', () {
    test('normalizedArticle 小写去空格，无冠词返回 null', () {
      expect(NounArticle.normalizedArticle(makeWord(id: 1, article: ' Der ')),
          'der');
      expect(NounArticle.normalizedArticle(makeWord(id: 1)), isNull);
    });

    test('isAnswered 需单词 id 与冠词同时匹配', () {
      final w = makeWord(id: 10, article: 'das', wordType: 'noun');
      expect(NounArticle.isAnswered(w, 'das', 10), isTrue);
      expect(NounArticle.isAnswered(w, 'der', 10), isFalse); // 选错
      expect(NounArticle.isAnswered(w, 'das', 11), isFalse); // 切词后失效
      expect(NounArticle.isAnswered(w, null, 10), isFalse); // 未作答
    });
  });

  test('三色选择器顺序与翻牌模式一致（die/das/der）', () {
    expect(NounArticle.articles, ['die', 'das', 'der']);
  });
}
