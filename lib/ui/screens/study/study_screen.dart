import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/study_provider.dart';
import 'widgets/flip_mode_screen.dart';
import 'widgets/de_to_cn_screen.dart';
import 'widgets/cn_to_de_screen.dart';
import 'widgets/listen_mode_screen.dart';
import 'widgets/spell_mode_screen.dart';

/// 背词模式选择界面
class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDeck = ref.watch(activeDeckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择学习模式'),
      ),
      body: activeDeck.when(
        data: (deck) {
          if (deck == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '请先选择一个词书',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在主页切换词书，或在词书管理中创建',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 词书信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.library_books,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '当前词书',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              deck.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '选择学习模式',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _StudyModeCard(
                icon: Icons.flip_to_back,
                title: '经典翻牌模式',
                subtitle: '正面德语，背面释义，手动评分',
                color: Theme.of(context).colorScheme.primaryContainer,
                onTap: () => _startStudy(context, ref, deck.id, 'flip'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.translate,
                title: '看德语选中文',
                subtitle: '显示德语单词，选择正确中文释义',
                color: Theme.of(context).colorScheme.secondaryContainer,
                onTap: () => _startStudy(context, ref, deck.id, 'de_to_cn'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.g_translate,
                title: '看中文选德语',
                subtitle: '显示中文释义，选择正确德语单词',
                color: Theme.of(context).colorScheme.tertiaryContainer,
                onTap: () => _startStudy(context, ref, deck.id, 'cn_to_de'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.hearing,
                title: '听德语选单词',
                subtitle: '播放 TTS 发音，选择对应单词',
                color: Theme.of(context).colorScheme.errorContainer,
                onTap: () => _startStudy(context, ref, deck.id, 'listen'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.keyboard,
                title: '德语拼写模式',
                subtitle: '输入德语单词拼写，支持特殊字符',
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                onTap: () => _startStudy(context, ref, deck.id, 'spell'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
    );
  }

  void _startStudy(
      BuildContext context, WidgetRef ref, int deckId, String mode) async {
    // 开始学习会话
    final notifier = ref.read(studySessionProvider.notifier);
    await notifier.startSession(deckId: deckId);

    final session = ref.read(studySessionProvider);
    if (session.words.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有待学习的单词，请先导入词书')),
        );
      }
      return;
    }

    if (context.mounted) {
      Widget screen;
      switch (mode) {
        case 'flip':
          screen = const FlipModeScreen();
          break;
        case 'de_to_cn':
          screen = const DeToCnScreen();
          break;
        case 'cn_to_de':
          screen = const CnToDeScreen();
          break;
        case 'listen':
          screen = const ListenModeScreen();
          break;
        case 'spell':
          screen = const SpellModeScreen();
          break;
        default:
          screen = const FlipModeScreen();
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }
}

class _StudyModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StudyModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
