import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';
import 'package:wortapp/ui/screens/study/widgets/distractor_pool_mixin.dart';

void main() {
  Word makeWord(int id, String german, String chinese, {int deckId = 1}) {
    return Word(
      id: id,
      deckId: deckId,
      german: german,
      chinese: chinese,
      proficiency: 0,
      isFavorite: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('DistractorPool.pick', () {
    test('从候选池随机抽取 3 个干扰项并排除正确答案', () {
      final words = [
        makeWord(1, 'Haus', '房子'),
        makeWord(2, 'Buch', '书'),
        makeWord(3, 'Apfel', '苹果'),
        makeWord(4, 'Wasser', '水'),
        makeWord(5, 'Auto', '汽车'),
      ];
      final result = DistractorPool(words).pick(
        correctWord: words[0],
        selector: (w) => w.chinese,
      );
      expect(result, hasLength(3));
      expect(result, isNot(contains('房子')), reason: '不应包含正确答案');
      expect(result.toSet(), hasLength(3), reason: '干扰项不应重复');
    });

    test('选项文本去重：同释义单词只出现一次', () {
      final words = [
        makeWord(1, 'Haus', '房子'),
        makeWord(2, 'Buch', '书'),
        makeWord(3, 'Gebäude', '房子'), // 与正确答案同释义
        makeWord(4, 'Wasser', '水'),
        makeWord(5, 'Auto', '汽车'),
        makeWord(6, 'Straße', '街'),
      ];
      final result = DistractorPool(words).pick(
        correctWord: words[0],
        selector: (w) => w.chinese,
      );
      expect(result, hasLength(3));
      expect(result.toSet(), hasLength(3));
      expect(result, isNot(contains('房子')));
    });

    test('候选不足时返回可用的全部', () {
      final words = [
        makeWord(1, 'Haus', '房子'),
        makeWord(2, 'Buch', '书'),
      ];
      final result = DistractorPool(words).pick(
        correctWord: words[0],
        selector: (w) => w.chinese,
      );
      expect(result, hasLength(1));
      expect(result, contains('书'));
    });

    test('抽取数量不超过指定 count', () {
      final words =
          List.generate(10, (i) => makeWord(i + 1, 'wort$i', '释义$i'));
      final result = DistractorPool(words).pick(
        correctWord: words.first,
        selector: (w) => w.german,
        count: 2,
      );
      expect(result, hasLength(2));
    });

    test('支持德语单词选择器（看中文选德语/听音选词模式）', () {
      final words = [
        makeWord(1, 'Haus', '房子'),
        makeWord(2, 'Buch', '书'),
        makeWord(3, 'Apfel', '苹果'),
        makeWord(4, 'Wasser', '水'),
        makeWord(5, 'Auto', '汽车'),
      ];
      final result = DistractorPool(words).pick(
        correctWord: words[0],
        selector: (w) => w.german,
      );
      expect(result, hasLength(3));
      expect(result, isNot(contains('Haus')));
    });
  });

  group('StudySession.distractorPool', () {
    test('会话默认选项池为空，可携带启动时生成的选项池', () {
      final session = const StudySession(words: []);
      expect(session.distractorPool, isEmpty);

      final pool = [makeWord(1, 'Haus', '房子'), makeWord(2, 'Buch', '书')];
      final withPool = StudySession(words: [], distractorPool: pool);
      expect(withPool.distractorPool, same(pool));
    });

    test('copyWith 保留选项池引用', () {
      final pool = [makeWord(1, 'Haus', '房子')];
      final session = StudySession(words: [], distractorPool: pool);
      final copied = session.copyWith(currentIndex: 1);
      expect(copied.distractorPool, same(pool));
    });

    test('选项池为空时 DistractorPool 返回空干扰项（候选不足场景）', () {
      final result = DistractorPool(const []).pick(
        correctWord: makeWord(1, 'Haus', '房子'),
        selector: (w) => w.chinese,
      );
      expect(result, isEmpty);
    });
  });
}
