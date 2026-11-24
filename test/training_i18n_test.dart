import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/core/i18n/translations_de.dart';
import 'package:wortapp/core/i18n/translations_en.dart';

/// 训练模块文案覆盖检查
///
/// i18n_test.dart 只保证「英/德两张表的 key 集合一致」，无法发现
/// 「界面上新写了中文文案，但没加翻译」的情况。这里直接扫描训练模块源码里
/// `tr('…')` / `trArgs('…')` 的字面量，要求每个中文 key 都在两张表里。
void main() {
  test('训练模块界面文案都有英文与德文翻译', () {
    final sources = <File>[
      ..._dartFiles('lib/ui/screens/training'),
      ..._dartFiles('lib/ui/widgets'),
      ...Directory('lib/providers')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('training_provider.dart')),
    ];

    final pattern = RegExp(
      r"""(?:\.tr|\.trArgs)\(\s*'([^'\\]*)'""",
    );

    final missing = <String, List<String>>{};
    for (final file in sources) {
      final content = file.readAsStringSync();
      for (final match in pattern.allMatches(content)) {
        final key = match.group(1)!;
        if (key.isEmpty) continue;
        final missingIn = <String>[
          if (!kEnTranslations.containsKey(key)) 'en',
          if (!kDeTranslations.containsKey(key)) 'de',
        ];
        if (missingIn.isNotEmpty) {
          missing.putIfAbsent(key, () => missingIn);
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason: '以下文案缺少翻译（key → 缺失语言）：$missing',
    );
  });
}

List<File> _dartFiles(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}
