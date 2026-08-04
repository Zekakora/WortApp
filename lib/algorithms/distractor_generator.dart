import 'dart:math';
import '../data/database/app_database.dart';

/// 干扰项生成器
///
/// 用于选择题模式，生成干扰选项
class DistractorGenerator {
  final AppDatabase _db;
  final Random _random = Random();

  DistractorGenerator(this._db);

  /// 生成干扰项（中文释义）
  ///
  /// [correctWord] 正确答案的单词
  /// [deckId] 词书 ID
  /// [count] 干扰项数量（默认 3）
  Future<List<String>> generateChineseDistractors({
    required Word correctWord,
    required int deckId,
    int count = 3,
  }) async {
    final allWords = await _db.wordDao.getWordsByDeck(deckId);

    // 过滤掉正确答案
    final candidates = allWords
        .where((w) => w.id != correctWord.id)
        .toList();

    if (candidates.length <= count) {
      // 候选词不足，返回所有可用的
      return candidates.map((w) => w.chinese).toList();
    }

    // 优先选择同词性的单词
    final sameType = candidates
        .where((w) => w.wordType == correctWord.wordType)
        .toList();

    final distractors = <String>[];
    final used = <int>{};

    // 先从同词性中选
    if (sameType.length >= count) {
      final shuffled = List<Word>.from(sameType)..shuffle(_random);
      for (var i = 0; i < count && i < shuffled.length; i++) {
        distractors.add(shuffled[i].chinese);
        used.add(shuffled[i].id);
      }
    } else {
      // 同词性不足，先添加所有同词性
      for (final w in sameType) {
        distractors.add(w.chinese);
        used.add(w.id);
      }

      // 再从其他词性中随机选择
      final remaining = candidates
          .where((w) => !used.contains(w.id))
          .toList()
        ..shuffle(_random);

      for (var i = 0;
          distractors.length < count && i < remaining.length;
          i++) {
        distractors.add(remaining[i].chinese);
        used.add(remaining[i].id);
      }
    }

    return distractors;
  }

  /// 生成干扰项（德语单词）
  ///
  /// [correctWord] 正确答案的单词
  /// [deckId] 词书 ID
  /// [count] 干扰项数量（默认 3）
  Future<List<String>> generateGermanDistractors({
    required Word correctWord,
    required int deckId,
    int count = 3,
  }) async {
    final allWords = await _db.wordDao.getWordsByDeck(deckId);

    // 过滤掉正确答案
    final candidates = allWords
        .where((w) => w.id != correctWord.id)
        .toList();

    if (candidates.length <= count) {
      return candidates.map((w) => w.german).toList();
    }

    // 优先选择长度相近或拼写相似的单词
    final sorted = List<Word>.from(candidates)
      ..sort((a, b) {
        final aDiff = (a.german.length - correctWord.german.length).abs();
        final bDiff = (b.german.length - correctWord.german.length).abs();
        return aDiff.compareTo(bDiff);
      });

    // 从前 50% 中随机选择（优先相似的）
    final similarPool = sorted.take((sorted.length * 0.5).ceil()).toList();
    final otherPool = sorted.skip(similarPool.length).toList();

    final distractors = <String>[];
    final used = <int>{};

    // 从相似池中选 2 个
    similarPool.shuffle(_random);
    for (var i = 0;
        distractors.length < 2 && i < similarPool.length;
        i++) {
      distractors.add(similarPool[i].german);
      used.add(similarPool[i].id);
    }

    // 从其他池中选剩余的
    otherPool.shuffle(_random);
    for (var i = 0;
        distractors.length < count && i < otherPool.length;
        i++) {
      distractors.add(otherPool[i].german);
      used.add(otherPool[i].id);
    }

    // 如果还不够，从相似池补充
    if (distractors.length < count) {
      for (var i = 0;
          distractors.length < count && i < similarPool.length;
          i++) {
        if (!used.contains(similarPool[i].id)) {
          distractors.add(similarPool[i].german);
        }
      }
    }

    return distractors;
  }

  /// 生成选择题选项（包含正确答案）
  ///
  /// [correctAnswer] 正确答案
  /// [distractors] 干扰项列表
  /// 返回打乱顺序的选项列表和正确答案的索引
  ChoiceQuestion generateChoiceQuestion({
    required String correctAnswer,
    required List<String> distractors,
  }) {
    final options = [correctAnswer, ...distractors];
    options.shuffle(_random);

    final correctIndex = options.indexOf(correctAnswer);

    return ChoiceQuestion(
      options: options,
      correctIndex: correctIndex,
    );
  }
}

/// 选择题
class ChoiceQuestion {
  final List<String> options;
  final int correctIndex;

  const ChoiceQuestion({
    required this.options,
    required this.correctIndex,
  });

  String get correctAnswer => options[correctIndex];
}
