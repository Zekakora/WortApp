import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/training_provider.dart';
import '../../../../services/speech/speech_playback_service.dart';

/// 听力材料播放控件
///
/// 能力边界（与 SpeechPlaybackService 一致）：
/// - 整段播放 / 逐句播放 / 停止 / 重播；
/// - 语速跟随设置里的 `ttsSpeed`；
/// - **不提供暂停**：Android 上的 pause 仅 API ≥ 26 有效，统一用停止+重播；
/// - 德语语音不可用时整个控件替换为说明文字，不显示无效按钮。
class SpeechControls extends ConsumerStatefulWidget {
  final String text;

  /// 是否默认展开"逐句"模式
  final bool sentenceMode;

  final bool enabled;

  const SpeechControls({
    super.key,
    required this.text,
    this.sentenceMode = false,
    this.enabled = true,
  });

  @override
  ConsumerState<SpeechControls> createState() => _SpeechControlsState();
}

class _SpeechControlsState extends ConsumerState<SpeechControls> {
  bool _playing = false;
  int? _activeSentence;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final service = ref.read(trainingSpeechProvider);
    await service.initialize(
      rate: ref.read(settingsProvider).ttsSpeed,
    );
    if (mounted) setState(() {});
  }

  Future<void> _playWhole() async {
    final service = ref.read(trainingSpeechProvider);
    setState(() {
      _playing = true;
      _activeSentence = null;
    });
    await service.speak(widget.text);
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _playSentenceBySentence() async {
    final service = ref.read(trainingSpeechProvider);
    final sentences = SpeechPlaybackService.splitSentences(widget.text);
    setState(() => _playing = true);
    await service.speakSequence(
      sentences,
      onPartStarted: (index) {
        if (mounted) setState(() => _activeSentence = index);
      },
    );
    if (mounted) {
      setState(() {
        _playing = false;
        _activeSentence = null;
      });
    }
  }

  Future<void> _stop() async {
    await ref.read(trainingSpeechProvider).stop();
    if (mounted) {
      setState(() {
        _playing = false;
        _activeSentence = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final service = ref.watch(trainingSpeechProvider);
    final available = service.isAvailable;

    if (!service.isInitialized) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (!available) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.volume_off, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('此设备没有德语语音，无法播放听力材料'),
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: widget.enabled
                    ? (_playing
                        ? _stop
                        : (widget.sentenceMode
                            ? _playSentenceBySentence
                            : _playWhole))
                    : null,
                icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _playing ? context.tr('停止') : context.tr('播放'),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.sentenceMode && !_playing)
                TextButton.icon(
                  onPressed: widget.enabled ? _playWhole : null,
                  icon: const Icon(Icons.subject, size: 18),
                  label: Text(context.tr('整段')),
                ),
              const Spacer(),
              IconButton(
                tooltip: context.tr('重播'),
                onPressed: widget.enabled
                    ? (_playing
                        ? _stop
                        : (widget.sentenceMode
                            ? _playSentenceBySentence
                            : _playWhole))
                    : null,
                icon: const Icon(Icons.replay),
              ),
            ],
          ),
          if (_activeSentence != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.trArgs('正在播放第 {0} 句', [_activeSentence! + 1]),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
