/// 语音播放服务（任务书 §3.1、§7 的 SpeechPlaybackService）
///
/// 把 `flutter_tts` 封装成可替换的一层，UI 不再直接调用插件：
/// - 统一设置德语 `de-DE` 与语速；
/// - **先检测德语语音是否可用**，不可用时返回原因，UI 据此隐藏播放入口，
///   避免出现"点了没反应"的无效控件；
/// - 提供整段播放与逐句播放；
/// - 不提供 pause：`flutter_tts` 在 Android 上的 pause 是 workaround
///   （依赖 `onRangeStart`，仅 API ≥ 26 有效），而本项目 `minSdk` 走 Flutter 默认值，
///   统一用「停止 + 重播」语义更可靠（任务书允许优雅降级）。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 不可用原因
enum SpeechUnavailableReason {
  /// 系统没有安装德语语音
  noGermanVoice,

  /// 平台/插件能力不支持
  unsupported,

  /// 其他错误
  error,
}

/// 语音播放状态
enum SpeechPlaybackState { idle, playing, stopped }

/// 德语语音播放服务
class SpeechPlaybackService {
  final FlutterTts _tts;

  double _rate = 0.5;
  bool _initialized = false;
  bool _cancelled = false;
  SpeechPlaybackState _state = SpeechPlaybackState.idle;
  SpeechUnavailableReason? _unavailableReason;

  SpeechPlaybackService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  bool get isInitialized => _initialized;
  bool get isAvailable => _initialized && _unavailableReason == null;
  SpeechUnavailableReason? get unavailableReason => _unavailableReason;
  SpeechPlaybackState get playbackState => _state;

  /// 初始化：设置德语与语速，并检测德语语音可用性
  ///
  /// 重复调用只会重新应用语速，不会重复注册回调。
  Future<bool> initialize({double? rate}) async {
    if (rate != null) _rate = rate;
    try {
      if (!_initialized) {
        await _tts.setLanguage('de-DE');
        await _tts.setSpeechRate(_rate);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        // 让 speak() 在朗读结束后才 resolve，逐句播放依赖这个行为
        await _tts.awaitSpeakCompletion(true);
        _tts.setCompletionHandler(() {
          _state = SpeechPlaybackState.idle;
        });
        _tts.setCancelHandler(() {
          _state = SpeechPlaybackState.stopped;
        });
        _tts.setErrorHandler((message) {
          debugPrint('TTS 错误: $message');
          _state = SpeechPlaybackState.idle;
        });
        _initialized = true;
      }
      await _tts.setSpeechRate(_rate);

      // 德语语音检测：部分设备只装了英语语音
      try {
        final available = await _tts.isLanguageAvailable('de-DE');
        final isAvailable = available == true || available == 1;
        _unavailableReason =
            isAvailable ? null : SpeechUnavailableReason.noGermanVoice;
      } catch (e) {
        // Web / 部分桌面端不支持查询语言，按"可用"处理，让播放本身报错
        debugPrint('查询德语语音失败（按可用处理）: $e');
        _unavailableReason = null;
      }
      return isAvailable;
    } catch (e) {
      debugPrint('TTS 初始化失败: $e');
      _initialized = true;
      _unavailableReason = SpeechUnavailableReason.error;
      return false;
    }
  }

  /// 应用新语速（设置变化时调用）
  Future<void> setRate(double rate) async {
    _rate = rate;
    if (!_initialized) return;
    try {
      await _tts.setSpeechRate(rate);
    } catch (e) {
      debugPrint('设置语速失败: $e');
    }
  }

  /// 停止当前朗读
  Future<void> stop() async {
    _cancelled = true;
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('停止朗读失败: $e');
    }
    _state = SpeechPlaybackState.stopped;
  }

  /// 朗读整段文本（等待读完）
  Future<void> speak(String text) async {
    final content = text.trim();
    if (content.isEmpty) return;
    if (_unavailableReason != null) return;

    _cancelled = false;
    _state = SpeechPlaybackState.playing;
    try {
      await _tts.stop();
      await _tts.speak(content);
    } catch (e) {
      debugPrint('朗读失败: $e');
    } finally {
      _state = SpeechPlaybackState.idle;
    }
  }

  /// 逐句朗读（听力材料的"逐句播放"）
  ///
  /// [onPartStarted] 在每句开始前回调，便于 UI 高亮当前句。
  /// 返回是否完整播完（被停止时为 false）。
  Future<bool> speakSequence(
    List<String> parts, {
    void Function(int index)? onPartStarted,
  }) async {
    final sentences = parts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (sentences.isEmpty || _unavailableReason != null) return false;

    _cancelled = false;
    _state = SpeechPlaybackState.playing;
    try {
      for (var i = 0; i < sentences.length; i++) {
        if (_cancelled) return false;
        onPartStarted?.call(i);
        await _tts.speak(sentences[i]);
      }
      return !_cancelled;
    } catch (e) {
      debugPrint('逐句朗读失败: $e');
      return false;
    } finally {
      _state = SpeechPlaybackState.idle;
    }
  }

  /// 把德语文本切成句子（用于逐句播放）
  static List<String> splitSentences(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    final parts = trimmed
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? [trimmed] : parts;
  }

  void dispose() {
    _cancelled = true;
    try {
      _tts.stop();
    } catch (_) {
      // 忽略：dispose 阶段不该再抛
    }
  }
}
