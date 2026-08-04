import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../services/dictionary/dictionary_engine.dart';
import '../../../ui/widgets/word_type_chip.dart';
import '../../../ui/widgets/inflection_widgets.dart';

/// 联网查词界面
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterTts _tts = FlutterTts();

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
        title: const Text('联网查词'),
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
                    hintText: '输入德语单词...',
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
                    ],
                  ),
                ),
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
              label: const Text('加入词书'),
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
            '输入德语单词开始查词',
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
                      '复数: ${result.plural}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (result.partOfSpeech != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '词性: ${result.partOfSpeech}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 8),
                        // 词性彩色标签
                        WordTypeChip(
                          wordType: result.partOfSpeech,
                          article: result.article,
                          compact: true,
                          showLabel: false,
                        ),
                        // 名词可数/不可数标签
                        if (result.nounType != null) ...[
                          const SizedBox(width: 8),
                          NounTypeChip(
                            nounType: result.nounType,
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (result.separablePrefix != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '可分前缀: ${result.separablePrefix}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (result.baseVerb != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '基础动词: ${result.baseVerb}',
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
                      '释义',
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
                          '动词搭配',
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
                                      isDative ? '三格' : '四格',
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
                    Row(
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
                        const Text('三格 (Dativ)', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 16),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('四格 (Akkusativ)', style: TextStyle(fontSize: 12)),
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
                      '例句',
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
                          'AI 深度解析',
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
        ? ('动词变位', Icons.auto_fix_high)
        : isNoun
            ? ('名词变格', Icons.category)
            : ('形容词变级', Icons.trending_up);

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
    const tenseMeta = [
      ('praesens', '现在时', 'Präsens'),
      ('praeteritum', '过去时', 'Präteritum'),
      ('perfekt', '完成时', 'Perfekt'),
      ('passiv', '被动态', 'Passiv'),
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
        InflectionRow(label: '第二格', value: noun.genitiv!),
      if (noun.plural != null) InflectionRow(label: '复数', value: noun.plural!),
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
        InflectionRow(label: '比较级', value: adj.komparativ!),
      if (adj.superlativ != null)
        InflectionRow(label: '最高级', value: adj.superlativ!),
      if (adj.komparativ == null && adj.superlativ == null)
        const SizedBox.shrink(),
    ];
  }

  void _performSearch() {
    final word = _searchController.text.trim();
    if (word.isEmpty) return;

    ref.read(searchProvider.notifier).lookup(word);
  }

  void _showAddToDeckDialog(
      BuildContext context, DictionaryResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _DeckSelectionSheet(
          result: result,
          onAddToDeck: (deckId) => _addToDeck(context, deckId, result),
          onCreateDeck: () => _createAndAdd(context, result),
        );
      },
    );
  }

  void _addToDeck(
      BuildContext context, int deckId, DictionaryResult result) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据库未就绪')),
        );
      }
      return;
    }

    // 检查是否已存在
    final existing = await db.wordDao.findWordByGerman(deckId, result.word);
    if (existing != null) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该单词已在词书中')),
        );
      }
      return;
    }

    // 添加单词（含变格数据：动词三态/名词第二格/形容词变级）
    final now = DateTime.now();
    final infFields = Inflection.wordsFields(result);
    await db.wordDao.createWord(
      WordsCompanion(
        deckId: drift.Value(deckId),
        german: drift.Value(result.word),
        article: drift.Value(result.article),
        baseForm: drift.Value(result.word),
        wordType: drift.Value(result.partOfSpeech),
        chinese: drift.Value(
            result.definitions.isNotEmpty ? result.definitions.first : ''),
        example: drift.Value(
            result.examples.isNotEmpty ? result.examples.first : null),
        nounType: drift.Value(result.nounType),
        nounPlural: drift.Value(result.plural),
        verbPresent: infFields['verbPresent'] == null
            ? const drift.Value.absent()
            : drift.Value(infFields['verbPresent']),
        verbPast: infFields['verbPast'] == null
            ? const drift.Value.absent()
            : drift.Value(infFields['verbPast']),
        verbPerfect: infFields['verbPerfect'] == null
            ? const drift.Value.absent()
            : drift.Value(infFields['verbPerfect']),
        nounGenitive: infFields['nounGenitive'] == null
            ? const drift.Value.absent()
            : drift.Value(infFields['nounGenitive']),
        adjComparative: infFields['adjComparative'] == null
            ? const drift.Value.absent()
            : drift.Value(infFields['adjComparative']),
        adjSuperlative: infFields['adjSuperlative'] == null
            ? const drift.Value.absent()
            : drift.Value(infFields['adjSuperlative']),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // 变格数据写入 conjugation_cache，与变格练习打通
    final newWord = await db.wordDao.findWordByGerman(deckId, result.word);
    final inflectionJson = result.normalizedInflection;
    if (newWord != null &&
        inflectionJson != null &&
        !Inflection.isEmpty(inflectionJson)) {
      await db.conjugationDao.upsert(newWord.id, jsonEncode(inflectionJson));
    }

    // 确保AI结果被缓存（查词时可能已缓存，这里再确认一次）
    if (result.engine == 'AI 解析') {
      try {
        final existingCache = await db.aiCacheDao.getCachedResult(result.word);
        if (existingCache == null) {
          // 如果缓存不存在，重建并保存（包含所有字段）
          final cacheJson = jsonEncode({
            'word': result.word,
            'article': result.article ?? '',
            'plural': result.plural ?? '',
            'definitions': result.definitions,
            'examples': result.examples,
            'part_of_speech': result.partOfSpeech ?? '',
            'analysis': result.aiAnalysis ?? '',
            'verb_type': result.verbType,
            'conjugation': result.conjugation ?? {},
            'separable_prefix': result.separablePrefix,
            'base_verb': result.baseVerb,
            'collocations': result.collocations?.map((c) => {
              'pattern': c.pattern,
              'case': c.caseType,
              'meaning': c.meaning,
            }).toList() ?? [],
            'noun_type': result.nounType,
            'inflection': result.normalizedInflection,
          });
          await db.aiCacheDao.saveToCache(
            word: result.word,
            resultJson: cacheJson,
          );
        }
      } catch (e) {
        debugPrint('缓存保存失败: $e');
      }
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加到词书')),
      );
    }
  }

  void _createAndAdd(BuildContext context, DictionaryResult result) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建词书'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '词书名称',
            hintText: '例如：生词本',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

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

              if (context.mounted) {
                Navigator.pop(context); // 关闭对话框
                Navigator.pop(context); // 关闭底部弹窗
                _addToDeck(context, deckId, result);
              }
            },
            child: const Text('创建并添加'),
          ),
        ],
      ),
    );
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

/// 词书选择底部弹窗
class _DeckSelectionSheet extends ConsumerWidget {
  final DictionaryResult result;
  final Function(int deckId) onAddToDeck;
  final VoidCallback onCreateDeck;

  const _DeckSelectionSheet({
    required this.result,
    required this.onAddToDeck,
    required this.onCreateDeck,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(allDecksProvider);

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
                  Text(
                    '选择词书',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onCreateDeck,
                    icon: const Icon(Icons.add),
                    label: const Text('新建词书'),
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
                        '还没有词书，请先创建一个',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      return ListTile(
                        leading: Icon(
                          deck.isActive
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: deck.isActive
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(deck.name),
                        subtitle: deck.description != null
                            ? Text(deck.description!)
                            : null,
                        onTap: () => onAddToDeck(deck.id),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('错误: $e')),
              ),
            ),
          ],
        );
      },
    );
  }
}
