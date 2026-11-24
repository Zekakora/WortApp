import 'package:flutter/material.dart';

import 'translations_de.dart';
import 'translations_en.dart';

/// 翻译核心：以中文原文为 key，未命中时回退中文原文。
///
/// 选择「以中文原文为 key」而非语义化 key 的原因：
/// 项目已有数百条硬编码中文文案，直接以原文作为 key 迁移成本最低，
/// 且缺失翻译时能自动回退，不会出现空白或抛错。
String translateFor(String languageCode, String zh) {
  switch (languageCode) {
    case 'en':
      return kEnTranslations[zh] ?? zh;
    case 'de':
      return kDeTranslations[zh] ?? zh;
    default:
      return zh;
  }
}

/// 带占位符的翻译：key 中使用 `{0}`、`{1}`…占位。
String translateArgsFor(String languageCode, String zh, List<Object?> args) {
  var result = translateFor(languageCode, zh);
  for (var i = 0; i < args.length; i++) {
    result = result.replaceAll('{$i}', '${args[i]}');
  }
  return result;
}

/// 全局语言状态（供非 Widget 环境使用：算法、Provider、Service 等）。
///
/// 由应用根节点在语言设置变化时同步；Widget 内请优先使用
/// `context.l10n` / `context.tr` 以获得自动重建能力。
class AppLocale {
  AppLocale._();

  static const String zh = 'zh';
  static const String en = 'en';
  static const String de = 'de';

  /// 当前语言代码：'zh' / 'en' / 'de'
  static String code = zh;

  static String tr(String zhText) => translateFor(code, zhText);

  static String trArgs(String zhText, List<Object?> args) =>
      translateArgsFor(code, zhText, args);
}

/// Widget 环境使用的本地化对象：依赖 Flutter 的 Localizations，
/// 语言变化时依赖它的 Widget 会自动重建。
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale(AppLocale.zh),
    Locale(AppLocale.en),
    Locale(AppLocale.de),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale(AppLocale.zh));

  String get languageCode => locale.languageCode;

  bool get isChinese => languageCode == AppLocale.zh;

  String t(String zhText) => translateFor(languageCode, zhText);

  String tArgs(String zhText, List<Object?> args) =>
      translateArgsFor(languageCode, zhText, args);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const [AppLocale.zh, AppLocale.en, AppLocale.de]
          .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// 便捷扩展：`context.l10n.t('设置')` / `context.tr('设置')`。
extension AppLocalizationsContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// 翻译单条文案
  String tr(String zhText) => AppLocalizations.of(this).t(zhText);

  /// 翻译带占位符的文案，如 `context.trArgs('共 {0} 个', [n])`
  String trArgs(String zhText, List<Object?> args) =>
      AppLocalizations.of(this).tArgs(zhText, args);
}
