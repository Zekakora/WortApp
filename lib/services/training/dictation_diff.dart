/// 听写词级差异分析（对应任务书 §3.1「听写需区分实质词汇错误与表面差异」）
///
/// 用 LCS（最长公共子序列）对齐用户答案与标准答案的词序列，
/// 产出 遗漏 / 替换 / 多余 三类差异，并在替换里再区分：
/// - 纯大小写差异（`haus` vs `Haus`）
/// - 拼写近似（编辑距离 1，如 `fruend` vs `Freund`）
/// - 实质错词
///
/// 评分 = 命中词数 / 标准答案词数（漏写与错写都扣分，多写不额外扣分但要报告）。
library;

import 'answer_normalizer.dart';

/// 单词级差异类型
enum DictationDiffKind { missing, replaced, extra, caseOnly, spelling }

/// 一处差异
class DictationDiffItem {
  final DictationDiffKind kind;

  /// 标准答案里的词（extra 时为 null）
  final String? expected;

  /// 用户写的词（missing 时为 null）
  final String? actual;

  /// 在第几个词位（0 基，按标准答案序列；extra 时为插入点）
  final int position;

  const DictationDiffItem({
    required this.kind,
    this.expected,
    this.actual,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (expected != null) 'expected': expected,
    if (actual != null) 'actual': actual,
    'position': position,
  };

  String get hintZh => switch (kind) {
    DictationDiffKind.missing => '漏写',
    DictationDiffKind.replaced => '写错',
    DictationDiffKind.extra => '多写',
    DictationDiffKind.caseOnly => '大小写',
    DictationDiffKind.spelling => '拼写',
  };
}

/// 听写判分结果
class DictationResult {
  /// 0..1
  final double accuracy;
  final int expectedCount;
  final int matchedCount;
  final List<DictationDiffItem> diffs;

  const DictationResult({
    required this.accuracy,
    required this.expectedCount,
    required this.matchedCount,
    required this.diffs,
  });

  bool get isPerfect => expectedCount > 0 && matchedCount == expectedCount;

  /// 实质错误（漏写/错词/多写），大小写与拼写单列
  List<DictationDiffItem> get substantiveErrors => diffs
      .where(
        (d) =>
            d.kind == DictationDiffKind.missing ||
            d.kind == DictationDiffKind.replaced ||
            d.kind == DictationDiffKind.extra,
      )
      .toList();

  Map<String, dynamic> toJson() => {
    'accuracy': accuracy,
    'expectedCount': expectedCount,
    'matchedCount': matchedCount,
    'diffs': diffs.map((d) => d.toJson()).toList(),
  };
}

/// 听写差异分析器
class DictationDiff {
  DictationDiff._();

  /// 把文本切成词（保留德语变音符号与 ß；标点视为分隔符）
  static List<String> tokenize(String text) {
    final unified = AnswerNormalizer.normalize(
      text,
      const NormalizeOptions(ignorePunctuation: true, collapseWhitespace: true),
    );
    if (unified.isEmpty) return const [];
    return unified.split(' ').where((w) => w.isNotEmpty).toList();
  }

  /// 比较用户听写与标准答案
  static DictationResult compare(String userAnswer, String expectedAnswer) {
    final actual = tokenize(userAnswer);
    final expected = tokenize(expectedAnswer);

    if (expected.isEmpty) {
      return DictationResult(
        accuracy: actual.isEmpty ? 1 : 0,
        expectedCount: 0,
        matchedCount: 0,
        diffs: const [],
      );
    }

    final table = _lcsTable(expected, actual);
    final diffs = <DictationDiffItem>[];
    var matched = 0;

    // 回溯 LCS，得到对齐操作
    var i = expected.length;
    var j = actual.length;
    final ops = <_Op>[];
    while (i > 0 && j > 0) {
      if (_sameWord(expected[i - 1], actual[j - 1])) {
        ops.add(_Op.match(i - 1, j - 1));
        i--;
        j--;
      } else if (table[i - 1][j] >= table[i][j - 1]) {
        ops.add(_Op.missing(i - 1));
        i--;
      } else {
        ops.add(_Op.extra(j - 1));
        j--;
      }
    }
    while (i > 0) {
      ops.add(_Op.missing(--i));
    }
    while (j > 0) {
      ops.add(_Op.extra(--j));
    }
    ops.sort((a, b) => a.expectedPos.compareTo(b.expectedPos));

    // 相邻的 missing + extra 合并成"替换"，语义更清楚
    final merged = <_Op>[];
    for (var k = 0; k < ops.length; k++) {
      final op = ops[k];
      if (op.kind == _OpKind.missing &&
          k + 1 < ops.length &&
          ops[k + 1].kind == _OpKind.extra) {
        merged.add(_Op.replace(op.expectedPos, ops[k + 1].actualPos));
        k++;
      } else {
        merged.add(op);
      }
    }

    for (final op in merged) {
      switch (op.kind) {
        case _OpKind.match:
          matched++;
          final expectedWord = expected[op.expectedPos];
          final actualWord = actual[op.actualPos];
          if (expectedWord != actualWord) {
            diffs.add(
              DictationDiffItem(
                kind: DictationDiffKind.caseOnly,
                expected: expectedWord,
                actual: actualWord,
                position: op.expectedPos,
              ),
            );
          }
        case _OpKind.missing:
          diffs.add(
            DictationDiffItem(
              kind: DictationDiffKind.missing,
              expected: expected[op.expectedPos],
              position: op.expectedPos,
            ),
          );
        case _OpKind.extra:
          diffs.add(
            DictationDiffItem(
              kind: DictationDiffKind.extra,
              actual: actual[op.actualPos],
              position: op.expectedPos,
            ),
          );
        case _OpKind.replace:
          final expectedWord = expected[op.expectedPos];
          final actualWord = actual[op.actualPos];
          final kind = _isNearMiss(expectedWord, actualWord)
              ? DictationDiffKind.spelling
              : DictationDiffKind.replaced;
          diffs.add(
            DictationDiffItem(
              kind: kind,
              expected: expectedWord,
              actual: actualWord,
              position: op.expectedPos,
            ),
          );
      }
    }

    return DictationResult(
      accuracy: (matched / expected.length).clamp(0.0, 1.0),
      expectedCount: expected.length,
      matchedCount: matched,
      diffs: diffs,
    );
  }

  static bool _sameWord(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();

  /// 编辑距离 ≤1 视为拼写近似
  static bool _isNearMiss(String a, String b) {
    final x = a.toLowerCase();
    final y = b.toLowerCase();
    if ((x.length - y.length).abs() > 1) return false;
    return _levenshtein(x, y) <= 1;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final deletion = prev[j] + 1;
        final insertion = curr[j - 1] + 1;
        final substitution = prev[j - 1] + cost;
        curr[j] = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
  }

  static List<List<int>> _lcsTable(List<String> a, List<String> b) {
    final table = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        table[i][j] = _sameWord(a[i - 1], b[j - 1])
            ? table[i - 1][j - 1] + 1
            : (table[i - 1][j] > table[i][j - 1]
                  ? table[i - 1][j]
                  : table[i][j - 1]);
      }
    }
    return table;
  }
}

enum _OpKind { match, missing, extra, replace }

class _Op {
  final _OpKind kind;
  final int expectedPos;
  final int actualPos;

  _Op.match(this.expectedPos, this.actualPos) : kind = _OpKind.match;
  _Op.missing(this.expectedPos) : kind = _OpKind.missing, actualPos = -1;
  _Op.extra(this.actualPos) : kind = _OpKind.extra, expectedPos = actualPos;
  _Op.replace(this.expectedPos, this.actualPos) : kind = _OpKind.replace;
}
