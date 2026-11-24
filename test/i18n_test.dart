import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/core/i18n/app_localizations.dart';
import 'package:wortapp/core/i18n/translations_de.dart';
import 'package:wortapp/core/i18n/translations_en.dart';

void main() {
  group('translateFor', () {
    test('中文直接返回原文', () {
      expect(translateFor('zh', '设置'), '设置');
    });

    test('英文查表命中', () {
      expect(translateFor('en', '设置'), 'Settings');
      expect(translateFor('en', '取消'), 'Cancel');
    });

    test('德文查表命中', () {
      expect(translateFor('de', '设置'), 'Einstellungen');
      expect(translateFor('de', '取消'), 'Abbrechen');
    });

    test('未命中回退中文原文', () {
      expect(translateFor('en', '这是一条不存在的文案'), '这是一条不存在的文案');
      expect(translateFor('de', '这是一条不存在的文案'), '这是一条不存在的文案');
    });
  });

  group('translateArgsFor', () {
    test('占位符替换（中文）', () {
      expect(translateArgsFor('zh', '共 {0} 个', [5]), '共 5 个');
    });

    test('占位符替换（英文，含多个参数）', () {
      expect(
        translateArgsFor('en', '恢复词书: {0}', [3]),
        'Wordbooks restored: 3',
      );
      expect(
        translateArgsFor('de', '• 词书 {0} 个 / 单词 {1} 个\n\n', [2, 10]),
        '• 2 Wortlisten / 10 Wörter\n\n',
      );
    });
  });

  group('AppLocale 全局语言', () {
    test('默认中文，切换后跟随', () {
      final original = AppLocale.code;
      try {
        AppLocale.code = 'en';
        expect(AppLocale.tr('设置'), 'Settings');
        AppLocale.code = 'de';
        expect(AppLocale.tr('设置'), 'Einstellungen');
        AppLocale.code = 'zh';
        expect(AppLocale.tr('设置'), '设置');
      } finally {
        AppLocale.code = original;
      }
    });
  });

  group('翻译表完整性', () {
    test('英文与德文 key 集合一致', () {
      final en = kEnTranslations.keys.toSet();
      final de = kDeTranslations.keys.toSet();
      expect(en.difference(de), isEmpty, reason: '仅英文有的 key');
      expect(de.difference(en), isEmpty, reason: '仅德文有的 key');
    });

    test('翻译表非空', () {
      expect(kEnTranslations.length, greaterThan(500));
      expect(kDeTranslations.length, greaterThan(500));
    });
  });
}
