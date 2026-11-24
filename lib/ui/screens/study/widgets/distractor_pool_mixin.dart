import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/database/app_database.dart';
import '../../../../providers/study_provider.dart';

/// 干扰项候选池（纯逻辑，可独立测试）
class DistractorPool {
  final List<Word> words;

  const DistractorPool(this.words);

  /// 从候选池随机抽取 [count] 个干扰项
  ///
  /// - 排除 [correctWord] 自身
  /// - 按 [selector] 提取的选项文本去重（避免同释义/同词形重复出现）
  /// - 候选不足时返回可用的全部
  List<String> pick({
    required Word correctWord,
    required String Function(Word) selector,
    int count = 3,
  }) {
    final candidates = words.where((w) => w.id != correctWord.id).toList()
      ..shuffle();
    final used = <String>{selector(correctWord)};
    final result = <String>[];
    for (final w in candidates) {
      if (result.length >= count) break;
      final text = selector(w);
      if (used.contains(text)) continue;
      result.add(text);
      used.add(text);
    }
    return result;
  }
}

/// 四选一模式的干扰项抽取混入
///
/// 选项池在会话启动时（[StudySession.distractorPool]）从所有词库一次性随机
/// 抽取“每轮单词数 × 5”个单词生成；整个会话中每道题的干扰项都从该池中
/// 同步抽取，无异步加载、无二次刷新。
mixin DistractorPoolMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// 从当前学习会话的选项池随机抽取 [count] 个干扰项
  List<String> pickDistractors({
    required Word correctWord,
    required String Function(Word) selector,
    int count = 3,
  }) {
    final pool = ref.read(studySessionProvider).distractorPool;
    return DistractorPool(
      pool,
    ).pick(correctWord: correctWord, selector: selector, count: count);
  }
}
