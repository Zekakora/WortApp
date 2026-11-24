import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/batch_update_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../services/ai/batch_ai_service.dart';
import '../../../services/dictionary/ai_dictionary_engine.dart';
import '../../../services/dictionary/dictionary_engine.dart';
import '../../../services/dictionary/word_intake_service.dart';
import '../../../ui/widgets/word_type_chip.dart';
import '../../../ui/widgets/inflection_widgets.dart';
import '../../../ui/widgets/batch_task_widgets.dart';

/// 联网查词界面
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterTts _tts = FlutterTts();

  /// 「查词后自动加入词书」后台任务串行队列：
  /// 连续查词时逐个执行，避免并发请求过多触发 API 限流
  static Future<void> _autoAddQueue = Future.value();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    // 每次发音前应用当前设置的语速，保证设置即时生效
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchResult = ref.watch(searchProvider);
    final selectedEngine = ref.watch(selectedEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('联网查词')),
        actions: const [
          // 后台 AI 任务进度按钮（查词后自动加入词书的任务也在此查看）
          BatchTaskProgressButton(),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 搜索输入框
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.tr('输入德语单词...'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchProvider.notifier).clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _performSearch(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // 引擎选择
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _EngineChip(
                        label: 'AI 解析',
                        icon: Icons.auto_awesome,
                        isSelected:
                            selectedEngine == DictionaryEngineType.ai,
                        onSelected: () {
                          ref.read(selectedEngineProvider.notifier).state =
                              DictionaryEngineType.ai;
                        },
                      ),
                      const SizedBox(width: 8),
                      _EngineChip(
                        label: 'Wiktionary',
                        icon: Icons.language,
                        isSelected:
                            selectedEngine == DictionaryEngineType.wiktionary,
                        onSelected: () {
                          ref.read(selectedEngineProvider.notifier).state =
                              DictionaryEngineType.wiktionary;
                        },
                      ),
                      const SizedBox(width: 8),
                      _EngineChip(
                        label: '德语助手',
                        icon: Icons.translate,
                        isSelected:
                            selectedEngine == DictionaryEngineType.godic,
                        onSelected: () {
                          ref.read(selectedEngineProvider.notifier).state =
                              DictionaryEngineType.godic;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 查词后自动加入词书设置入口
                _autoAddBar(colorScheme),
              ],
            ),
          ),
          // 搜索结果
          Expanded(
            child: searchResult.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchResult.error != null
                    ? _buildError(searchResult.error!, colorScheme)
                    : searchResult.result != null
                        ? _buildSearchResult(
                            context, searchResult.result!, colorScheme)
                        : searchResult.notice != null
                            ? _buildNotice(searchResult.notice!, colorScheme)
                            : _buildEmpty(colorScheme),
          ),
        ],
      ),
      // 加词入库按钮
      floatingActionButton: searchResult.result != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddToDeckDialog(
                  context, searchResult.result!),
              icon: const Icon(Icons.add),
              label: Text(context.tr('加入词书')),
            )
          : null,
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('输入德语单词开始查词'),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResult(
      BuildContext context, DictionaryResult result, ColorScheme colorScheme) {
    final genderColor = GenderColors.forArticle(result.article);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 单词头部
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (result.article != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: genderColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            result.article!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: genderColor,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.word,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => _speak(result.word),
                      ),
                    ],
                  ),
                  if (result.plural != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.trArgs('复数: {0}', [result.plural]),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (result.partOfSpeech != null) ...[
                    const SizedBox(height: 4),
                    // 用 Wrap 而非 Row：英文/德文界面文案更长，
                    // 窄屏下（含两个标签）会溢出，换行比截断更可读
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.trArgs('词性: {0}', [result.partOfSpeech]),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        // 词性彩色标签
                        WordTypeChip(
                          wordType: result.partOfSpeech,
                          article: result.article,
                          compact: true,
                          showLabel: false,
                        ),
                        // 名词可数/不可数标签
                        if (result.nounType != null)
                          NounTypeChip(
                            nounType: result.nounType,
                          ),
                      ],
                    ),
                  ],
                  if (result.separablePrefix != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.trArgs('可分前缀: {0}', [result.separablePrefix]),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (result.baseVerb != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.trArgs('基础动词: {0}', [result.baseVerb]),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 释义
          if (result.definitions.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('释义'),
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    ...result.definitions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${entry.key + 1}. ${entry.value}'),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // 变格/变位
          _buildInflectionCard(context, result, colorScheme),
          // 动词搭配
          if (result.collocations != null && result.collocations!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('动词搭配'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: result.collocations!.map((collocation) {
                        final isDative = collocation.caseType == 'dative';
                        final color = isDative ? Colors.green : Colors.purple;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isDative
                                          ? context.tr('三格')
                                          : context.tr('四格'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    collocation.pattern,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (collocation.meaning.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  collocation.meaning,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // 图例同样用 Wrap：窄屏 + 长语种文案时不至于溢出
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('三格 (Dativ)'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('四格 (Akkusativ)'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // 例句
          if (result.examples.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('例句'),
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    ...result.examples.map((example) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          example,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          // AI 解析
          if (result.aiAnalysis != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('AI 深度解析'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(result.aiAnalysis!),
                  ],
                ),
              ),
            ),
          ],
          // 底部间距
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 变格/变位卡片（数据来自 AI 返回的 inflection，与变格练习格式一致）
  Widget _buildInflectionCard(BuildContext context, DictionaryResult result,
      ColorScheme colorScheme) {
    final inflection = result.normalizedInflection;
    if (inflection == null || Inflection.isEmpty(inflection)) {
      return const SizedBox.shrink();
    }

    final isVerb = inflection['type'] == 'verb';
    final isNoun = inflection['type'] == 'noun';
    final (title, icon) = isVerb
        ? (context.tr('动词变位'), Icons.auto_fix_high)
        : isNoun
            ? (context.tr('名词变格'), Icons.category)
            : (context.tr('形容词变级'), Icons.trending_up);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isVerb) ..._buildVerbInflection(context, inflection, colorScheme)
            else if (isNoun) ..._buildNounInflection(context, inflection)
            else ..._buildAdjInflection(context, inflection),
          ],
        ),
      ),
    );
  }

  /// 动词：三个时态的 6 人称变位
  List<Widget> _buildVerbInflection(BuildContext context,
      Map<String, dynamic> inflection, ColorScheme colorScheme) {
    final tenseMeta = [
      ('praesens', context.tr('现在时'), 'Präsens'),
      ('praeteritum', context.tr('过去时'), 'Präteritum'),
      ('perfekt', context.tr('完成时'), 'Perfekt'),
      ('passiv', context.tr('被动态'), 'Passiv'),
    ];
    final tenses = Inflection.verbTenses(inflection);
    if (tenses == null) return const [SizedBox.shrink()];

    final perfektParts = Inflection.perfektParts(inflection);
    final widgets = <Widget>[];
    for (final (key, zh, de) in tenseMeta) {
      final persons = tenses[key];
      if (persons == null) continue;
      widgets.add(InflectionTenseBlock(
        zhLabel: zh,
        deLabel: de,
        header: key == 'perfekt' && (perfektParts.auxiliary != null ||
                perfektParts.partizip != null)
            ? '${perfektParts.auxiliary ?? ''} ${perfektParts.partizip ?? ''}'.trim()
            : null,
        persons: persons,
      ));
    }
    return widgets;
  }

  /// 名词：第二格 / 复数
  List<Widget> _buildNounInflection(
      BuildContext context, Map<String, dynamic> inflection) {
    final noun = Inflection.nounParts(inflection);
    return [
      if (noun.genitiv != null)
        InflectionRow(label: context.tr('第二格'), value: noun.genitiv!),
      if (noun.plural != null)
        InflectionRow(label: context.tr('复数'), value: noun.plural!),
      if (noun.genitiv == null && noun.plural == null)
        const SizedBox.shrink(),
    ];
  }

  /// 形容词：比较级 / 最高级
  List<Widget> _buildAdjInflection(
      BuildContext context, Map<String, dynamic> inflection) {
    final adj = Inflection.adjParts(inflection);
    return [
      if (adj.komparativ != null)
        InflectionRow(label: context.tr('比较级'), value: adj.komparativ!),
      if (adj.superlativ != null)
        InflectionRow(label: context.tr('最高级'), value: adj.superlativ!),
      if (adj.komparativ == null && adj.superlativ == null)
        const SizedBox.shrink(),
    ];
  }

  void _performSearch() {
    final word = _searchController.text.trim();
    if (word.isEmpty) return;

    final settings = ref.read(settingsProvider);
    // 开启「查词后自动加入词书」时走后台任务：立即返回，可继续查下一个单词
    if (settings.autoAddToDeckEnabled && settings.autoAddToDeckId != null) {
      _startAutoAddLookup(word);
    } else {
      ref.read(searchProvider.notifier).lookup(word);
    }
  }

  /// 查词后自动加入词书设置入口行
  Widget _autoAddBar(ColorScheme colorScheme) {
    final settings = ref.watch(settingsProvider);
    final decks = ref.watch(allDecksProvider).value ?? const <Deck>[];
    final enabled = settings.autoAddToDeckEnabled;
    Deck? targetDeck;
    for (final d in decks) {
      if (d.id == settings.autoAddToDeckId) {
        targetDeck = d;
        break;
      }
    }

    final statusText = !enabled
        ? context.tr('查词后自动加入词书')
        : targetDeck != null
            ? context.trArgs('自动加入：{0}', [targetDeck.name])
            : context.tr('自动加入：请选择词书');

    return Material(
      color: enabled
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _showAutoAddSettings,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                enabled
                    ? Icons.playlist_add_check_circle
                    : Icons.playlist_add_circle_outlined,
                size: 18,
                color: enabled
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 后台任务提示（查词后自动加入词书模式）
  Widget _buildNotice(String notice, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              notice,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('可点击右上角任务按钮查看进度，任务完成后自动加入词书'),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 打开自动加入词书设置弹窗
  void _showAutoAddSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AutoAddSettingsSheet(),
    );
  }

  /// 后台查词入库：加入任务队列立即返回，任务完成自动将单词加入目标词书
  void _startAutoAddLookup(String word) {
    final settings = ref.read(settingsProvider);
    final deckId = settings.autoAddToDeckId;
    if (deckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('请先设置自动加入的词书'))),
      );
      return;
    }

    // 校验目标词书仍存在
    final decks = ref.read(allDecksProvider).value ?? const <Deck>[];
    if (!decks.any((d) => d.id == deckId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('目标词书不存在，请重新选择'))),
      );
      return;
    }

    // 预先读取任务依赖（页面销毁后 ref 不可用，因此任务开始前全部取出）
    final db = ref.read(databaseProvider);
    final aiEngine = ref.read(aiDictionaryEngineProvider);
    if (db == null || aiEngine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('AI 引擎未就绪，请检查设置'))),
      );
      return;
    }
    final selectedEngine = ref.read(selectedEngineProvider);
    final engine = switch (selectedEngine) {
      DictionaryEngineType.ai => aiEngine,
      DictionaryEngineType.wiktionary => ref.read(wiktionaryEngineProvider),
      DictionaryEngineType.godic => ref.read(godicEngineProvider),
    };

    final notifier = ref.read(batchUpdateProvider.notifier);
    final taskId = notifier.addTask(
        context.trArgs('查词入库: {0}', [word]), 1, words: [word]);

    // 串行执行：前一个查词任务完成后才开始下一个，避免并发请求过多
    _autoAddQueue = _autoAddQueue.then((_) async {
      try {
        await _runAutoAddTask(taskId, word, deckId, notifier, db, aiEngine, engine);
      } catch (e) {
        // 防御性兜底，保证队列中的后续任务不被中断
        notifier.failTask(taskId, '任务异常: $e');
      }
    });

    // 清空输入框，方便直接输入下一个单词继续查词
    _searchController.clear();
    setState(() {});

    // 显示后台任务提示（不阻塞界面，结果返回后自动入库）
    ref.read(searchProvider.notifier).showNotice(
      context.trArgs('「{0}」已加入后台查询队列，完成后自动加入词书', [word]),
    );
  }

  /// 执行后台查词入库任务（在串行队列中运行，不阻塞查词界面）
  ///
  /// 所有依赖均在页面存活时预先传入，页面销毁后任务仍可正常运行
  Future<void> _runAutoAddTask(
    String taskId,
    String word,
    int deckId,
    BatchUpdateNotifier notifier,
    AppDatabase db,
    AIDictionaryEngine aiEngine,
    DictionaryEngine engine,
  ) async {
    notifier.startTask(taskId);

    final service = BatchAIService(db, aiEngine, concurrency: 1);
    try {
      final outcome = await service.lookupAndAddToDeck(
        word: word,
        deckId: deckId,
        engine: engine,
        onProgress: (p) => notifier.updateProgress(taskId, p),
      );
      final success = outcome == 'added' || outcome == 'exists';
      notifier.completeTask(
        taskId,
        BatchUpdateProgress(
          total: 1,
          completed: success ? 1 : 0,
          failed: success ? 0 : 1,
          isRunning: false,
        ),
      );
    } catch (e) {
      notifier.failTask(taskId, e.toString());
    }
  }

  void _showAddToDeckDialog(BuildContext context, DictionaryResult result) {
    // 提示条宿主提前取出：底部弹窗关闭后它依然有效，
    // 避免在已卸载的 context 上取 ScaffoldMessenger 而丢提示
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _DeckSelectionSheet(
          result: result,
          onAddToDeck: (deckId) => _addToDeck(deckId, result, messenger),
          onCreateDeck: (name) => _createDeckAndAdd(name, result, messenger),
        );
      },
    );
  }

  /// 全局规范化查重：同一词不允许在任何词书中重复
  /// （`der Hund` 与 `Hund` 归为同一词），命中时返回已存在的单词与所在词书。
  ///
  /// 查重规则集中在 [WordIntakeService]，训练模块的长按查词也走同一套逻辑。
  Future<({Word word, Deck? deck})?> _findExistingWord(
      DictionaryResult result) async {
    final db = ref.read(databaseProvider);
    if (db == null) return null;
    final existing = await WordIntakeService(db).findExisting(result);
    final word = existing?.existingWord;
    if (word == null) return null;
    return (word: word, deck: existing?.existingDeck);
  }

  /// 把查词结果写入指定词书（入库逻辑见 [WordIntakeService]）。
  ///
  /// 只负责入库与提示，**不**关闭任何弹窗：弹窗由各自的面板关闭，
  /// 否则多余的 `Navigator.pop` 会把根页面一起弹掉（首页只有一个路由，一旦被
  /// pop 就只剩黑屏）。
  Future<void> _addToDeck(
    int deckId,
    DictionaryResult result,
    ScaffoldMessengerState messenger,
  ) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('数据库未就绪'))),
      );
      return;
    }

    final outcome =
        await WordIntakeService(db).addToDeck(deckId: deckId, result: result);
    if (!mounted) return;

    final message = switch (outcome.status) {
      WordIntakeStatus.added => context.tr('已添加到词书'),
      WordIntakeStatus.alreadyExists => outcome.existingDeck == null
          ? context.tr('该单词已存在，未重复添加')
          : context.trArgs(
              '该单词已存在于词书「{0}」，未重复添加',
              [outcome.existingDeck!.name],
            ),
      WordIntakeStatus.failed =>
        context.trArgs('添加失败: {0}', [outcome.error ?? '']),
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
  /// 新建词书并立即把当前查词结果加入其中。
  ///
  /// 返回 `true` 表示已处理完毕（面板据此关闭），`false` 表示失败（面板保持展开，
  /// 用户可直接重试，不需要重新走一遍流程）。
  Future<bool> _createDeckAndAdd(
    String rawName,
    DictionaryResult result,
    ScaffoldMessengerState messenger,
  ) async {
    final name = rawName.trim();
    if (name.isEmpty) return false;

    final db = ref.read(databaseProvider);
    if (db == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('数据库未就绪'))),
      );
      return false;
    }

    try {
      // 先查重：单词已存在时不新建一本空词书
      final existing = await _findExistingWord(result);
      if (!mounted) return false;
      if (existing != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              existing.deck == null
                  ? context.tr('该单词已存在，未重复添加')
                  : context.trArgs(
                      '该单词已存在于词书「{0}」，未重复添加',
                      [existing.deck!.name],
                    ),
            ),
          ),
        );
        return true;
      }

      // 已存在同名词书时直接复用，避免出现两本同名书
      final decks = await db.deckDao.getAllDecks();
      int? reusedDeckId;
      for (final deck in decks) {
        if (deck.name.trim() == name) {
          reusedDeckId = deck.id;
          break;
        }
      }

      final now = DateTime.now();
      final deckId = reusedDeckId ??
          await db.deckDao.createDeck(
            DecksCompanion(
              name: drift.Value(name),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );
      await _addToDeck(deckId, result, messenger);
      return true;
    } catch (e) {
      if (!mounted) return false;
      messenger.showSnackBar(
        SnackBar(content: Text(context.trArgs('创建词书失败: {0}', [e]))),
      );
      return false;
    }
  }
}

class _EngineChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;

  const _EngineChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}

/// 查词后自动加入词书设置弹窗（开关 + 目标词书选择）
class _AutoAddSettingsSheet extends ConsumerWidget {
  const _AutoAddSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(allDecksProvider);
    final settings = ref.watch(settingsProvider);
    final enabled = settings.autoAddToDeckEnabled;
    final targetDeckId = settings.autoAddToDeckId;
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('查词后自动加入词书'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                              '开启后查词不再等待，自动挂到后台任务，完成后加入所选词书，可继续查下一个单词'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (v) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateAutoAddToDeck(v, deckId: targetDeckId);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Text(
                    context.tr('选择词书'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _createDeckForAutoAdd(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('新建词书')),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: decksAsync.when(
                data: (decks) {
                  if (decks.isEmpty) {
                    return Center(
                      child: Text(
                        context.tr('还没有词书，请先创建一个'),
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      final isSelected = enabled && deck.id == targetDeckId;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(deck.name),
                        subtitle: deck.description != null
                            ? Text(deck.description!)
                            : null,
                        trailing: isSelected
                            ? Text(
                                context.tr('当前目标'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                ),
                              )
                            : null,
                        onTap: () {
                          ref
                              .read(settingsProvider.notifier)
                              .updateAutoAddToDeck(true, deckId: deck.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(context.trArgs('错误: {0}', [e]))),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 新建词书并设为自动加入目标
  Future<void> _createDeckForAutoAdd(
      BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('新建词书')),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.tr('词书名称'),
            hintText: context.tr('例如：生词本'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, nameController.text.trim()),
            child: Text(context.tr('创建')),
          ),
        ],
      ),
    );
    nameController.dispose();

    if (name == null || name.isEmpty || !context.mounted) return;

    final db = ref.read(databaseProvider);
    if (db == null) return;

    final now = DateTime.now();
    final deckId = await db.deckDao.createDeck(
      DecksCompanion(
        name: drift.Value(name),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // 创建后直接设为自动加入目标并关闭弹窗
    await ref
        .read(settingsProvider.notifier)
        .updateAutoAddToDeck(true, deckId: deckId);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}

/// 词书选择底部弹窗
class _DeckSelectionSheet extends ConsumerStatefulWidget {
  final DictionaryResult result;
  final void Function(int deckId) onAddToDeck;

  /// 新建词书并入库；返回 `true` 表示处理完成（面板随后关闭），
  /// `false` 表示失败（面板保持展开，便于原地重试）
  final Future<bool> Function(String name) onCreateDeck;

  const _DeckSelectionSheet({
    required this.result,
    required this.onAddToDeck,
    required this.onCreateDeck,
  });

  @override
  ConsumerState<_DeckSelectionSheet> createState() =>
      _DeckSelectionSheetState();
}

class _DeckSelectionSheetState extends ConsumerState<_DeckSelectionSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _creating = false;
  bool _submitting = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleCreating() {
    setState(() {
      _creating = !_creating;
      _nameError = null;
      if (!_creating) _nameController.clear();
    });
  }

  Future<void> _submitNewDeck() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.tr('请填写词书名称'));
      return;
    }

    // 提前取出 Navigator：await 之后自身 context 可能已失效
    final navigator = Navigator.of(context);
    setState(() {
      _submitting = true;
      _nameError = null;
    });

    final done = await widget.onCreateDeck(name);
    if (!mounted) return;

    if (done) {
      navigator.pop();
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(allDecksProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('选择词书'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.trArgs('把「{0}」加入词书', [widget.result.word]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _submitting ? null : _toggleCreating,
                    icon: Icon(_creating ? Icons.close : Icons.add),
                    label: Text(context.tr(_creating ? '取消' : '新建词书')),
                  ),
                ],
              ),
            ),
            if (_creating) _buildCreateForm(colorScheme),
            const Divider(height: 1),
            Expanded(
              child: decksAsync.when(
                data: (decks) {
                  if (decks.isEmpty && !_creating) {
                    return _buildEmptyState(colorScheme);
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
                    ),
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      return ListTile(
                        enabled: !_submitting,
                        leading: Icon(
                          deck.isActive
                              ? Icons.check_circle
                              : Icons.book_outlined,
                          color: deck.isActive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          deck.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: deck.description != null
                            ? Text(
                                deck.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Icon(
                          Icons.add_circle_outline,
                          color: colorScheme.primary,
                        ),
                        onTap: () {
                          // 面板负责关闭自己，业务回调只做入库与提示，
                          // 避免多余的 pop 把页面一起弹掉
                          Navigator.of(context).pop();
                          widget.onAddToDeck(deck.id);
                        },
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.trArgs('错误: {0}', [e])),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 内联「新建词书」表单：直接在本面板输入名称，不再叠第二层对话框
  Widget _buildCreateForm(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            enabled: !_submitting,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitNewDeck(),
            decoration: InputDecoration(
              labelText: context.tr('词书名称'),
              hintText: context.tr('例如：生词本'),
              errorText: _nameError,
              prefixIcon: const Icon(Icons.drive_file_rename_outline),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submitting ? null : _submitNewDeck,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              _submitting ? context.tr('创建中...') : context.tr('创建并添加'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('还没有词书，请先创建一个'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => setState(() => _creating = true),
              icon: const Icon(Icons.add),
              label: Text(context.tr('新建词书')),
            ),
          ],
        ),
      ),
    );
  }
}
