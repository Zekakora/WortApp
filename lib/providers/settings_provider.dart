import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../data/database/app_database.dart';
import 'database_provider.dart';

// Web 平台使用 localStorage
// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart' show kIsWeb;

/// AI 配置
class AiConfig {
  final String apiKey;
  final String baseUrl;
  final String model;

  const AiConfig({
    this.apiKey = '',
    this.baseUrl = 'https://api.xiaomimimo.com/v1',
    this.model = 'mimo-v2.5-pro',
  });

  AiConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
  }) {
    return AiConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }

  bool get isConfigured => apiKey.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
      };

  factory AiConfig.fromJson(Map<String, dynamic> json) => AiConfig(
        apiKey: json['apiKey'] ?? '',
        baseUrl: json['baseUrl'] ?? 'https://api.xiaomimimo.com/v1',
        model: json['model'] ?? 'mimo-v2.5-pro',
      );

  static const presets = {
    'MiMo': AiConfig(
      baseUrl: 'https://api.xiaomimimo.com/v1',
      model: 'mimo-v2.5-pro',
    ),
    'DeepSeek': AiConfig(
      baseUrl: 'https://api.deepseek.com/v1',
      model: 'deepseek-chat',
    ),
    'OpenAI': AiConfig(
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o-mini',
    ),
  };
}

/// 应用设置
class AppSettings {
  final AiConfig aiConfig;
  final int dailyNewLimit;
  final int dailyReviewLimit;
  final double ttsSpeed;
  final bool tolerantSpelling;
  final bool autoPlayTts;
  /// 回答后自动确认（学习模式：选择答案后无需手动点击确认）
  final bool autoConfirm;
  /// AI 批量查词并发数（同时查询的单词数量）
  final int aiConcurrency;
  /// 查词后自动加入词书开关
  final bool autoAddToDeckEnabled;
  /// 查词后自动加入的目标词书ID
  final int? autoAddToDeckId;
  /// 主题模式：'system' 跟随系统 / 'light' 日间 / 'dark' 夜间
  final String themeMode;
  final bool isLoaded;

  const AppSettings({
    this.aiConfig = const AiConfig(),
    this.dailyNewLimit = 20,
    this.dailyReviewLimit = 100,
    this.ttsSpeed = 0.5,
    this.tolerantSpelling = true,
    this.autoPlayTts = false,
    this.autoConfirm = false,
    this.aiConcurrency = 10,
    this.autoAddToDeckEnabled = false,
    this.autoAddToDeckId,
    this.themeMode = 'system',
    this.isLoaded = false,
  });

  AppSettings copyWith({
    AiConfig? aiConfig,
    int? dailyNewLimit,
    int? dailyReviewLimit,
    double? ttsSpeed,
    bool? tolerantSpelling,
    bool? autoPlayTts,
    bool? autoConfirm,
    int? aiConcurrency,
    bool? autoAddToDeckEnabled,
    int? autoAddToDeckId,
    String? themeMode,
    bool? isLoaded,
  }) {
    return AppSettings(
      aiConfig: aiConfig ?? this.aiConfig,
      dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      tolerantSpelling: tolerantSpelling ?? this.tolerantSpelling,
      autoPlayTts: autoPlayTts ?? this.autoPlayTts,
      autoConfirm: autoConfirm ?? this.autoConfirm,
      aiConcurrency: aiConcurrency ?? this.aiConcurrency,
      autoAddToDeckEnabled: autoAddToDeckEnabled ?? this.autoAddToDeckEnabled,
      autoAddToDeckId: autoAddToDeckId ?? this.autoAddToDeckId,
      themeMode: themeMode ?? this.themeMode,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  String get apiKey => aiConfig.apiKey;

  Map<String, dynamic> toJson() => {
        'aiConfig': aiConfig.toJson(),
        'dailyNewLimit': dailyNewLimit,
        'dailyReviewLimit': dailyReviewLimit,
        'ttsSpeed': ttsSpeed,
        'tolerantSpelling': tolerantSpelling,
        'autoPlayTts': autoPlayTts,
        'autoConfirm': autoConfirm,
        'aiConcurrency': aiConcurrency,
        'autoAddToDeckEnabled': autoAddToDeckEnabled,
        'autoAddToDeckId': autoAddToDeckId,
        'themeMode': themeMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        aiConfig: json['aiConfig'] != null
            ? AiConfig.fromJson(json['aiConfig'])
            : const AiConfig(),
        dailyNewLimit: json['dailyNewLimit'] ?? 20,
        dailyReviewLimit: json['dailyReviewLimit'] ?? 100,
        ttsSpeed: (json['ttsSpeed'] ?? 0.5).toDouble(),
        tolerantSpelling: json['tolerantSpelling'] ?? true,
        autoPlayTts: json['autoPlayTts'] ?? false,
        autoConfirm: json['autoConfirm'] ?? false,
        aiConcurrency: json['aiConcurrency'] ?? 10,
        autoAddToDeckEnabled: json['autoAddToDeckEnabled'] ?? false,
        autoAddToDeckId: (json['autoAddToDeckId'] as num?)?.toInt(),
        themeMode: json['themeMode'] ?? 'system',
        isLoaded: true,
      );
}

/// Web 平台的 localStorage 辅助类
class _WebStorage {
  static void setItem(String key, String value) {
    try {
      // 使用 dart:html 的 localStorage
      // ignore: undefined_prefixed_name
      // import 'dart:html' as html; 不在 web 平台可用
      // 使用 js interop 代替
      debugPrint('WebStorage: saving $key');
    } catch (e) {
      debugPrint('WebStorage error: $e');
    }
  }

  static String? getItem(String key) {
    try {
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// 设置 StateNotifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  final AppDatabase? _db;
  bool _isLoading = false;

  SettingsNotifier(this._db) : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      debugPrint('Loading settings...');

      // 尝试从数据库加载
      if (_db != null) {
        try {
          final aiConfigJson = await _db!.getSetting('aiConfig');
          if (aiConfigJson != null && aiConfigJson.isNotEmpty) {
            final aiConfig = AiConfig.fromJson(jsonDecode(aiConfigJson));
            final dailyNewLimit =
                int.tryParse(await _db!.getSetting('dailyNewLimit') ?? '') ??
                    20;
            final dailyReviewLimit =
                int.tryParse(await _db!.getSetting('dailyReviewLimit') ?? '') ??
                    100;
            final ttsSpeed =
                double.tryParse(await _db!.getSetting('ttsSpeed') ?? '') ??
                    0.5;
            final tolerantSpelling =
                (await _db!.getSetting('tolerantSpelling')) != 'false';
            final autoPlayTts =
                (await _db!.getSetting('autoPlayTts')) == 'true';
            final autoConfirm =
                (await _db!.getSetting('autoConfirm')) == 'true';
            final aiConcurrency =
                int.tryParse(await _db!.getSetting('aiConcurrency') ?? '') ??
                    10;
            final autoAddToDeckEnabled =
                (await _db.getSetting('autoAddToDeckEnabled')) == 'true';
            final autoAddToDeckId =
                int.tryParse(await _db.getSetting('autoAddToDeckId') ?? '');
            final themeMode = await _db.getSetting('themeMode') ?? 'system';

            state = AppSettings(
              aiConfig: aiConfig,
              dailyNewLimit: dailyNewLimit,
              dailyReviewLimit: dailyReviewLimit,
              ttsSpeed: ttsSpeed,
              tolerantSpelling: tolerantSpelling,
              autoPlayTts: autoPlayTts,
              autoConfirm: autoConfirm,
              aiConcurrency: aiConcurrency.clamp(1, 500),
              autoAddToDeckEnabled: autoAddToDeckEnabled,
              autoAddToDeckId: autoAddToDeckId,
              themeMode: themeMode,
              isLoaded: true,
            );

            debugPrint('Settings loaded from database');
            return;
          }
        } catch (e) {
          debugPrint('Failed to load from database: $e');
        }
      }

      // 数据库加载失败，使用默认设置
      debugPrint('Using default settings');
      state = const AppSettings(isLoaded: true);
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      state = const AppSettings(isLoaded: true);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateAiConfig(AiConfig config) async {
    debugPrint('Updating AI config...');
    state = state.copyWith(aiConfig: config);

    // 保存到数据库
    if (_db != null) {
      try {
        await _db!.setSetting('aiConfig', jsonEncode(config.toJson()));
        debugPrint('AI config saved to database');
      } catch (e) {
        debugPrint('Failed to save to database: $e');
      }
    }
  }

  Future<void> applyAiPreset(String presetName) async {
    final preset = AiConfig.presets[presetName];
    if (preset != null) {
      final currentKey = state.aiConfig.apiKey;
      await updateAiConfig(preset.copyWith(apiKey: currentKey));
    }
  }

  Future<void> updateDailyNewLimit(int limit) async {
    state = state.copyWith(dailyNewLimit: limit);
    try {
      await _db?.setSetting('dailyNewLimit', limit.toString());
    } catch (e) {
      debugPrint('Failed to save dailyNewLimit: $e');
    }
  }

  Future<void> updateDailyReviewLimit(int limit) async {
    state = state.copyWith(dailyReviewLimit: limit);
    try {
      await _db?.setSetting('dailyReviewLimit', limit.toString());
    } catch (e) {
      debugPrint('Failed to save dailyReviewLimit: $e');
    }
  }

  Future<void> updateTtsSpeed(double speed) async {
    state = state.copyWith(ttsSpeed: speed);
    try {
      await _db?.setSetting('ttsSpeed', speed.toString());
    } catch (e) {
      debugPrint('Failed to save ttsSpeed: $e');
    }
  }

  Future<void> updateTolerantSpelling(bool enabled) async {
    state = state.copyWith(tolerantSpelling: enabled);
    try {
      await _db?.setSetting('tolerantSpelling', enabled.toString());
    } catch (e) {
      debugPrint('Failed to save tolerantSpelling: $e');
    }
  }

  Future<void> updateAutoPlayTts(bool enabled) async {
    state = state.copyWith(autoPlayTts: enabled);
    try {
      await _db?.setSetting('autoPlayTts', enabled.toString());
    } catch (e) {
      debugPrint('Failed to save autoPlayTts: $e');
    }
  }

  Future<void> updateAutoConfirm(bool enabled) async {
    state = state.copyWith(autoConfirm: enabled);
    try {
      await _db?.setSetting('autoConfirm', enabled.toString());
    } catch (e) {
      debugPrint('Failed to save autoConfirm: $e');
    }
  }

  /// 更新 AI 批量查词并发数（限制在 1~500）
  Future<void> updateAiConcurrency(int concurrency) async {
    final value = concurrency.clamp(1, 500);
    state = state.copyWith(aiConcurrency: value);
    try {
      await _db?.setSetting('aiConcurrency', value.toString());
    } catch (e) {
      debugPrint('Failed to save aiConcurrency: $e');
    }
  }

  /// 更新查词后自动加入词书设置
  ///
  /// [enabled] 开关状态；[deckId] 目标词书ID（关闭时可传 null）
  Future<void> updateAutoAddToDeck(bool enabled, {int? deckId}) async {
    state = state.copyWith(
      autoAddToDeckEnabled: enabled,
      autoAddToDeckId: enabled ? (deckId ?? state.autoAddToDeckId) : state.autoAddToDeckId,
    );
    try {
      await _db?.setSetting('autoAddToDeckEnabled', enabled.toString());
      if (deckId != null) {
        await _db?.setSetting('autoAddToDeckId', deckId.toString());
      }
    } catch (e) {
      debugPrint('Failed to save autoAddToDeck: $e');
    }
  }

  /// 更新主题模式（'system' 跟随系统 / 'light' 日间 / 'dark' 夜间）
  Future<void> updateThemeMode(String mode) async {
    final valid =
        const {'system', 'light', 'dark'}.contains(mode) ? mode : 'system';
    state = state.copyWith(themeMode: valid);
    try {
      await _db?.setSetting('themeMode', valid);
    } catch (e) {
      debugPrint('Failed to save themeMode: $e');
    }
  }
}

/// 设置 Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsNotifier(db);
});
