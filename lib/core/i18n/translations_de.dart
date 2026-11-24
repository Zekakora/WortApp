import 'parts/common.dart';
import 'parts/conjugation.dart';
import 'parts/core_strings.dart';
import 'parts/deck.dart';
import 'parts/home.dart';
import 'parts/search.dart';
import 'parts/settings.dart';
import 'parts/study.dart';
import 'parts/training.dart';

/// 德文翻译表（中文原文 → 德文）。
final Map<String, String> kDeTranslations = <String, String>{
  ...coreStringsDe,
  ...homeDe,
  ...deckDe,
  ...searchDe,
  ...settingsDe,
  ...studyDe,
  ...conjugationDe,
  ...trainingDe,
  // common 放最后：通用文案在各分片中重复出现，以 common 为准
  ...commonDe,
};
