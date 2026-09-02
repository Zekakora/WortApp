import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/study_provider.dart';
import 'study_stats_screen.dart';
import 'widgets/flip_mode_screen.dart';
import 'widgets/de_to_cn_screen.dart';
import 'widgets/cn_to_de_screen.dart';
import 'widgets/listen_mode_screen.dart';
import 'widgets/spell_mode_screen.dart';
import 'widgets/flash_card_screen.dart';

/// 背词模式选择界面
///
/// - 每轮单词数设置（10/20/50/自定义，持久化到数据库）
/// - 学习会话受每日新词/复习上限约束，上限用尽后自动复习今日已学单词
class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  static const _countKey = 'studyRoundWordCount';
  static const _presetCounts = [10, 20, 50];
  static const _pickModeKey = 'studyPickMode';

  /// 每轮单词数
  int _roundCount = 20;

  /// 抓词模式（正常 / 收藏优先 / 只抓收藏）
  WordPickMode _pickMode = WordPickMode.normal;

  @override
  void initState() {
    super.initState();
    _loadRoundCount();
    _loadPickMode();
  }

  /// 从数据库加载每轮单词数设置
  Future<void> _loadRoundCount() async {
    final db = ref.read(databaseProvider);
    final value = await db?.getSetting(_countKey);
    final parsed = int.tryParse(value ?? '');
    if (parsed != null && parsed > 0 && mounted) {
      setState(() => _roundCount = parsed);
    }
  }

  /// 保存每轮单词数设置
  Future<void> _setRoundCount(int count) async {
    if (count <= 0) return;
    setState(() => _roundCount = count);
    final db = ref.read(databaseProvider);
    try {
      await db?.setSetting(_countKey, count.toString());
    } catch (e) {
      debugPrint('保存每轮单词数失败: $e');
    }
  }

  /// 从数据库加载抓词模式设置
  Future<void> _loadPickMode() async {
    final db = ref.read(databaseProvider);
    final value = await db?.getSetting(_pickModeKey);
    final parsed = WordPickMode.values.where((m) => m.name == value).firstOrNull;
    if (parsed != null && mounted) {
      setState(() => _pickMode = parsed);
    }
  }

  /// 保存抓词模式设置
  Future<void> _setPickMode(WordPickMode mode) async {
    setState(() => _pickMode = mode);
    final db = ref.read(databaseProvider);
    try {
      await db?.setSetting(_pickModeKey, mode.name);
    } catch (e) {
      debugPrint('保存抓词模式失败: $e');
    }
  }

  /// 抓词模式说明文字
  String get _pickModeHint {
    switch (_pickMode) {
      case WordPickMode.favoriteBoost:
        return '今天该学的单词中，收藏词汇优先出现、被抓中概率更高';
      case WordPickMode.favoriteOnly:
        return '只练习今天该学单词中已收藏的词汇';
      case WordPickMode.wrongTodayOnly:
        return '只练习今天答错过（忘记/模糊）的词；答错会重新复习，连续 3 轮答对才移出';
      case WordPickMode.normal:
        return '按每日新词/复习上限正常抓取';
    }
  }

  /// 自定义每轮单词数对话框
  Future<void> _showCustomCountDialog() async {
    final controller = TextEditingController(text: _roundCount.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义每轮单词数'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '单词数量',
            hintText: '请输入正整数',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final count = int.tryParse(controller.text.trim());
              if (count != null && count > 0) {
                Navigator.pop(context, count);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的正整数')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      await _setRoundCount(result);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 12),
              // 练习参数：每轮单词数（类似变位练习的单次练习词量）
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '练习参数',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '每轮单词数',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: [
                          for (final count in _presetCounts)
                            ButtonSegment(
                              value: count,
                              label: Text('$count 个'),
                            ),
                          const ButtonSegment(
                            value: -1,
                            label: Text('自定义'),
                          ),
                        ],
                        selected: {
                          if (_presetCounts.contains(_roundCount))
                            _roundCount
                          else
                            -1,
                        },
                        onSelectionChanged: (selection) {
                          final value = selection.first;
                          if (value == -1) {
                            _showCustomCountDialog();
                          } else {
                            _setRoundCount(value);
                          }
                        },
                      ),
                      if (!_presetCounts.contains(_roundCount)) ...[
                        const SizedBox(height: 8),
                        Text(
                          '当前: $_roundCount 个',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '新词与复习受每日上限约束；上限用尽后进入循环复习：'
                        '每次学习发放一批（每轮单词数），分批覆盖今天全部'
                        '单词，覆盖完毕后自动开启下一大轮，轮数无上限',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '抓词模式',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<WordPickMode>(
                        segments: const [
                          ButtonSegment(
                            value: WordPickMode.normal,
                            label: Text('正常抓词'),
                          ),
                          ButtonSegment(
                            value: WordPickMode.favoriteBoost,
                            label: Text('收藏优先'),
                          ),
                          ButtonSegment(
                            value: WordPickMode.favoriteOnly,
                            label: Text('只抓收藏'),
                          ),
                          ButtonSegment(
                            value: WordPickMode.wrongTodayOnly,
                            label: Text('今日错词'),
                          ),
                        ],
                        selected: {_pickMode},
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (selection) {
                          _setPickMode(selection.first);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickModeHint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                icon: Icons.flash_on,
                title: '快闪卡模式',
                subtitle: '全屏卡片，限时回忆，滑动评分',
                color: Colors.amber.shade100,
                onTap: () => _startStudy(context, deck.id, 'flash_card'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.flip_to_back,
                title: '经典翻牌模式',
                subtitle: '正面德语，背面释义，手动评分',
                color: Theme.of(context).colorScheme.primaryContainer,
                onTap: () => _startStudy(context, deck.id, 'flip'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.translate,
                title: '看德语选中文',
                subtitle: '显示德语单词，选择正确中文释义',
                color: Theme.of(context).colorScheme.secondaryContainer,
                onTap: () => _startStudy(context, deck.id, 'de_to_cn'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.g_translate,
                title: '看中文选德语',
                subtitle: '显示中文释义，选择正确德语单词',
                color: Theme.of(context).colorScheme.tertiaryContainer,
                onTap: () => _startStudy(context, deck.id, 'cn_to_de'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.hearing,
                title: '听德语选单词',
                subtitle: '播放 TTS 发音，选择对应单词',
                color: Theme.of(context).colorScheme.errorContainer,
                onTap: () => _startStudy(context, deck.id, 'listen'),
              ),
              const SizedBox(height: 12),
              _StudyModeCard(
                icon: Icons.keyboard,
                title: '德语拼写模式',
                subtitle: '输入德语单词拼写，支持特殊字符',
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                onTap: () => _startStudy(context, deck.id, 'spell'),
              ),
              const SizedBox(height: 24),
              // 错误统计排行榜入口（今日/历史，二级页面）
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.bar_chart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('错误统计排行榜'),
                  subtitle: const Text('今日/历史的错误次数与错误率'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudyStatsScreen(deckId: deck.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
    );
  }

  Future<void> _startStudy(
      BuildContext context, int deckId, String mode) async {
    // 开始学习会话（受每日新词/复习上限与每轮单词数约束）
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(studySessionProvider.notifier);
    await notifier.startSession(
      deckId: deckId,
      dailyNewLimit: settings.dailyNewLimit,
      dailyReviewLimit: settings.dailyReviewLimit,
      roundLimit: _roundCount,
      pickMode: _pickMode,
    );

    final session = ref.read(studySessionProvider);
    if (session.words.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(session.error ?? '没有待学习的单词，请先导入词书'),
          ),
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
        case 'flash_card':
          screen = const FlashCardScreen();
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



