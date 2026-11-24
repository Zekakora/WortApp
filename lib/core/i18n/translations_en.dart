import 'parts/common.dart';
import 'parts/conjugation.dart';
import 'parts/core_strings.dart';
import 'parts/deck.dart';
import 'parts/home.dart';
import 'parts/search.dart';
import 'parts/settings.dart';
import 'parts/study.dart';

/// 英文翻译表（中文原文 → 英文）。
///
/// 使用非 const 的 Map 字面量以便各分片通过 spread 合并：
/// 允许不同分片出现重复 key（后加入者覆盖前者），避免 const 重复 key 编译错误。
final Map<String, String> kEnTranslations = <String, String>{
  ...coreStringsEn,
  ...homeEn,
  ...deckEn,
  ...searchEn,
  ...settingsEn,
  ...studyEn,
  ...conjugationEn,
  // common 放最后：通用文案（取消/保存等）在各分片中重复出现，以 common 为准
  ...commonEn,
};
