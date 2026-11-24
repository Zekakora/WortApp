import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../providers/study_provider.dart';
import 'cn_to_de_screen.dart';
import 'de_to_cn_screen.dart';
import 'flash_card_screen.dart';
import 'flip_mode_screen.dart';
import 'listen_mode_screen.dart';
import 'spell_mode_screen.dart';

/// 混合模式：每个词随机用一种已实现的答题方式
///
/// 实现方式是「按词换屏」而不是重写一套 UI：
/// 每次进入某个词时随机挑一个模式屏幕渲染该词，答完后会话推进到下一个词，
/// 本组件随之换成新词对应的模式屏幕。每个词的模式分配在内存里固定，
/// 同一个词不会因为重建而突然换题型。
class MixedModeScreen extends ConsumerStatefulWidget {
  const MixedModeScreen({super.key});

  @override
  ConsumerState<MixedModeScreen> createState() => _MixedModeScreenState();
}

class _MixedModeScreenState extends ConsumerState<MixedModeScreen> {
  /// 参与混合的模式（都是已实现的完整屏幕）
  static const _modes = [
    'flash_card',
    'flip',
    'de_to_cn',
    'cn_to_de',
    'listen',
    'spell',
  ];

  final Map<int, String> _assignments = {};
  final Random _random = Random();

  String _modeFor(int wordId) {
    return _assignments.putIfAbsent(
      wordId,
      () => _modes[_random.nextInt(_modes.length)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studySessionProvider);
    final word = session.currentWord;

    // 会话结束：给统一的完成页，不依赖各模式屏幕自己的空状态文案
    if (word == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('混合模式'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('本节练习完成'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('返回')),
              ),
            ],
          ),
        ),
      );
    }

    final mode = _modeFor(word.id);

    return KeyedSubtree(
      key: ValueKey('mixed-$mode-${word.id}-${session.currentIndex}'),
      child: switch (mode) {
        'flash_card' => const FlashCardScreen(),
        'de_to_cn' => const DeToCnScreen(),
        'cn_to_de' => const CnToDeScreen(),
        'listen' => const ListenModeScreen(),
        'spell' => const SpellModeScreen(),
        _ => const FlipModeScreen(),
      },
    );
  }
}
