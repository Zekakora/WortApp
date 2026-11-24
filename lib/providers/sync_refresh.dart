import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'conjugation_provider.dart';
import 'deck_provider.dart';
import 'settings_provider.dart';
import 'study_provider.dart';

/// 同步 / 恢复 / 导入等「直接写数据库」的操作完成后，统一刷新依赖数据库的 Provider。
///
/// 这些 Provider（`FutureProvider` / `FutureProvider.family`）会缓存计算结果，
/// 若不在写库后主动失效，界面（尤其主页的「连续打卡」「待复习」卡片）会一直
/// 显示操作前的旧数据——看起来就像“同步没生效”。
///
/// `StreamProvider`（`allDecksProvider` / `activeDeckProvider` / `wordsByDeckProvider`）
/// 会自动跟随数据库变化，这里一并失效只是为了立即重查，避免短暂的空窗。
///
/// 注意：**不**失效 `studySessionProvider`，避免打断用户正在进行的学习会话；
/// 依赖它的 `studyPlanProvider` / `checkInStreakProvider` 单独失效即可。
void invalidateDbDerivedProviders(WidgetRef ref) {
  // 设置（AI 配置、TTS、每日上限、抓词模式等）
  ref.invalidate(settingsProvider);

  // 词书与单词
  ref.invalidate(allDecksProvider);
  ref.invalidate(activeDeckProvider);
  ref.invalidate(wordCountProvider); // family：整族失效
  ref.invalidate(allWordsForStudyProvider); // family

  // 学习计划（待复习）与连续打卡
  ref.invalidate(studyPlanProvider); // family
  ref.invalidate(checkInStreakProvider);

  // 变位缓存相关
  ref.invalidate(conjugationDrillProvider);
  ref.invalidate(deckConjugationCacheProvider); // family
}
