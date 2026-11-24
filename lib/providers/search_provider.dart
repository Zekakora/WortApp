import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/i18n/app_localizations.dart';
import '../services/ai/ai_service.dart';
import '../services/dictionary/dictionary_engine.dart';
import '../services/dictionary/ai_dictionary_engine.dart';
import '../services/dictionary/wiktionary_engine.dart';
import '../services/dictionary/godic_engine.dart';
import 'settings_provider.dart';
import 'database_provider.dart';

/// 查词引擎类型
enum DictionaryEngineType {
  ai,
  wiktionary,
  godic,
}

/// 当前选择的查词引擎
final selectedEngineProvider =
    StateProvider<DictionaryEngineType>((ref) => DictionaryEngineType.ai);

/// AI 查词引擎 Provider
final aiDictionaryEngineProvider = Provider<AIDictionaryEngine?>((ref) {
  final settings = ref.watch(settingsProvider);
  final aiConfig = settings.aiConfig;

  if (!aiConfig.isConfigured) return null;

  final aiService = ConfigurableAIService(
    apiKey: aiConfig.apiKey,
    baseUrl: aiConfig.baseUrl,
    model: aiConfig.model,
  );

  return AIDictionaryEngine(
    aiService,
    cacheCallback: (word, resultJson) async {
      final db = ref.read(databaseProvider);
      if (db != null) {
        await db.aiCacheDao.saveToCache(
          word: word,
          resultJson: resultJson,
        );
      }
    },
    getCacheCallback: (word) async {
      final db = ref.read(databaseProvider);
      if (db != null) {
        final cached = await db.aiCacheDao.getCachedResult(word);
        return cached?.resultJson;
      }
      return null;
    },
    statusCallback: (word, success, error) async {
      final db = ref.read(databaseProvider);
      if (db != null) {
        await db.aiStatusDao.record(
          word: word,
          success: success,
          error: error,
        );
      }
    },
  );
});

/// Wiktionary 查词引擎 Provider
final wiktionaryEngineProvider = Provider<WiktionaryEngine>((ref) {
  return WiktionaryEngine();
});

/// 德语助手（godic.net）查词引擎 Provider
final godicEngineProvider = Provider<GedicDictionaryEngine>((ref) {
  return GedicDictionaryEngine();
});

/// 查词结果
class SearchResult {
  final bool isLoading;
  final DictionaryResult? result;
  final String? error;
  /// 提示信息（如「已加入后台查询队列」），非错误状态
  final String? notice;

  const SearchResult({
    this.isLoading = false,
    this.result,
    this.error,
    this.notice,
  });

  SearchResult copyWith({
    bool? isLoading,
    DictionaryResult? result,
    String? error,
    String? notice,
  }) {
    return SearchResult(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
      notice: notice,
    );
  }
}

/// 查词 StateNotifier
class SearchNotifier extends StateNotifier<SearchResult> {
  final Ref _ref;

  SearchNotifier(this._ref) : super(const SearchResult());

  /// 查词
  Future<void> lookup(String word) async {
    if (word.trim().isEmpty) {
      state = const SearchResult();
      return;
    }

    state = const SearchResult(isLoading: true);

    try {
      final engineType = _ref.read(selectedEngineProvider);
      DictionaryResult? result;

      switch (engineType) {
        case DictionaryEngineType.ai:
          final engine = _ref.read(aiDictionaryEngineProvider);
          if (engine == null) {
            state = SearchResult(
              error: AppLocale.tr('请先在设置中配置 AI API Key'),
            );
            return;
          }
          result = await engine.lookup(word);
          break;
        case DictionaryEngineType.wiktionary:
          final engine = _ref.read(wiktionaryEngineProvider);
          result = await engine.lookup(word);
          break;
        case DictionaryEngineType.godic:
          final engine = _ref.read(godicEngineProvider);
          result = await engine.lookup(word);
          break;
      }

      if (result != null) {
        state = SearchResult(result: result);
      } else {
        state = SearchResult(
          error: AppLocale.tr('未找到结果'),
        );
      }
    } catch (e) {
      state = SearchResult(error: AppLocale.trArgs('查词失败: {0}', [e]));
    }
  }

  /// 清除结果
  void clear() {
    state = const SearchResult();
  }

  /// 显示提示信息（查词后自动加入词书模式下，单词已加入后台队列）
  void showNotice(String notice) {
    state = SearchResult(notice: notice);
  }
}

/// 查词 Provider
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchResult>((ref) {
  return SearchNotifier(ref);
});
