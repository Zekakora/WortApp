import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/batch_update_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../ui/widgets/word_type_chip.dart';
import '../../../ui/widgets/inflection_widgets.dart';
import '../../../services/dictionary/dictionary_engine.dart';
import '../../../services/dictionary/ai_dictionary_engine.dart';

/// 单词详情页面
class WordDetailScreen extends ConsumerStatefulWidget {
  final int wordId;

  const WordDetailScreen({super.key, required this.wordId});

  @override
  ConsumerState<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends ConsumerState<WordDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  Word? _word;
  Sm2State? _sm2State;
  DictionaryResult? _aiResult;
  Map<String, dynamic>? _conjugationCache; // 变格缓存（与变格练习/单词列表同源）
  bool _isLoading = true;
  bool _isLoadingAi = false;
  bool _isWaitingForBatch = false; // 单词已在后台AI查询队列中

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadWordData();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadWordData() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    try {
      final word = await db.wordDao.getWordById(widget.wordId);
      final sm2State = await db.sm2Dao.getStateByWordId(widget.wordId);
      // 读取变格缓存（缓存优先，回退 words 表字段，与列表摘要/练习一致）
      final cacheData = await db.conjugationDao.getByWordId(widget.wordId);
      Map<String, dynamic>? cacheJson;
      if (cacheData != null) {
        try {
          final decoded = jsonDecode(cacheData.conjugationJson);
          if (decoded is Map<String, dynamic>) cacheJson = decoded;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _word = word;
          _sm2State = sm2State;
          _conjugationCache = cacheJson;
          _isLoading = false;
        });
        // 自动加载AI结果
        _loadAiResult();
      }
    } catch (e) {
      debugPrint('Failed to load word data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _speak(String text) async {
    // 每次发音前应用当前设置的语速，保证设置即时生效
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    await _tts.speak(text);
  }

  Future<void> _loadAiResult() async {
    if (_word == null) return;

    setState(() {
      _isLoadingAi = true;
    });

    try {
      final db = ref.read(databaseProvider);
      if (db == null) return;

      // 先检查缓存
      final cached = await db.aiCacheDao.getCachedResult(_word!.german);
      if (cached != null) {
        try {
          // 解析缓存的JSON数据
          final parsedResult = AIDictionaryEngine.parseResult(_word!.german, cached.resultJson);
          setState(() {
            _aiResult = parsedResult;
            _isLoadingAi = false;
            _isWaitingForBatch = false;
          });
          // AI结果自动写回words表，保证单词列表实时显示释义与词性
          if (parsedResult.definitions.isNotEmpty) {
            await _persistAiResultToWord(parsedResult);
          }
          return;
        } catch (e) {
          debugPrint('缓存解析失败，重新查询: $e');
        }
      }

      // 检查单词是否已在 AI 批量查询队列中（排队/运行中），
      // 避免详情页重复触发AI查询浪费token；任务完成后由 ref.listen 自动重新加载
      if (ref.read(batchUpdateProvider.notifier).isWordPending(_word!.german)) {
        debugPrint('单词已在AI查询队列中，跳过重复查询: ${_word!.german}');
        if (mounted) {
          setState(() {
            _isLoadingAi = false;
            _isWaitingForBatch = true;
          });
        }
        return;
      }

      // 调用AI查词
      final engine = ref.read(aiDictionaryEngineProvider);
      if (engine == null) {
        setState(() {
          _isLoadingAi = false;
          _isWaitingForBatch = false;
        });
        return;
      }

      final result = await engine.lookup(_word!.german);
      if (result != null && mounted) {
        setState(() {
          _aiResult = result;
          _isLoadingAi = false;
          _isWaitingForBatch = false;
        });
        // AI结果自动写回words表，保证单词列表实时显示释义与词性
        if (result.definitions.isNotEmpty) {
          await _persistAiResultToWord(result);
        }
      } else if (mounted) {
        setState(() {
          _isLoadingAi = false;
          _isWaitingForBatch = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load AI result: $e');
      if (mounted) {
        setState(() {
          _isLoadingAi = false;
          _isWaitingForBatch = false;
        });
      }
    }
  }

  /// 将AI解析结果写回words表，保证单词列表实时显示释义与词性。
  /// 仅更新AI提供的非空字段，避免覆盖用户已有的其他数据。
  Future<void> _persistAiResultToWord(DictionaryResult result) async {
    final db = ref.read(databaseProvider);
    final word = _word;
    if (db == null || word == null) return;

    final validDefinitions =
        result.definitions.where((d) => d.trim().isNotEmpty).toList();
    if (validDefinitions.isEmpty) return;

    final aiChinese = validDefinitions.first.trim();
    // 同步变格数据（AI 结果 → words 变格字段 + conjugation_cache），
    // 与“查词加入词书/批量更新”行为保持一致；手动编辑的变位数据不被覆盖
    await _syncInflection(db, word, result);
    // 释义与词性均无变化时无需重复写库，避免无谓的列表刷新
    if (word.chinese.trim() == aiChinese &&
        (result.partOfSpeech == null ||
            word.wordType == result.partOfSpeech)) {
      return;
    }

    try {
      await db.wordDao.updateWord(
        WordsCompanion(
          chinese: drift.Value(aiChinese),
          article: result.article == null
              ? const drift.Value.absent()
              : drift.Value(result.article),
          wordType: result.partOfSpeech == null
              ? const drift.Value.absent()
              : drift.Value(result.partOfSpeech),
          nounType: result.nounType == null
              ? const drift.Value.absent()
              : drift.Value(result.nounType),
          nounPlural: result.plural == null
              ? const drift.Value.absent()
              : drift.Value(result.plural),
          example: result.examples.isEmpty
              ? const drift.Value.absent()
              : drift.Value(result.examples.first),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // 刷新本地单词数据，使详情页头部同步显示
      final updated = await db.wordDao.getWordById(word.id);
      if (updated != null && mounted) {
        setState(() {
          _word = updated;
        });
      }
    } catch (e) {
      debugPrint('AI结果写回words表失败: $e');
    }
  }

  /// 将 AI 结果中的变格数据同步到 words 表变格字段与 conjugation_cache。
  ///
  /// 数据未变化时跳过写库；手动编辑（source='manual'）的变位数据不被覆盖。
  Future<void> _syncInflection(
      AppDatabase db, Word word, DictionaryResult result) async {
    final inflectionJson = result.normalizedInflection;
    if (inflectionJson == null || Inflection.isEmpty(inflectionJson)) return;
    try {
      final existing = await db.conjugationDao.getByWordId(word.id);
      if (existing?.source == 'manual') return;

      final newJson = jsonEncode(inflectionJson);
      if (existing != null && existing.conjugationJson.trim() == newJson) {
        return; // 内容未变化，不重复写库
      }

      final infFields = Inflection.wordsFields(result);
      await db.wordDao.updateWord(
        WordsCompanion(
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
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      await db.conjugationDao.upsert(word.id, newJson);

      // 刷新本地数据，使详情页变位区域同步显示
      final updated = await db.wordDao.getWordById(word.id);
      if (updated != null && mounted) {
        setState(() {
          _word = updated;
          _conjugationCache = inflectionJson;
        });
      }
    } catch (e) {
      debugPrint('变格数据同步失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听批量AI查询任务：当前单词的队列状态从“待处理”变为“已处理”时，
    // 自动重新加载AI结果（此时优先命中缓存，不重复调用AI、不浪费token）
    ref.listen(batchUpdateProvider, (previous, next) {
      final word = _word?.german;
      if (word == null) return;
      final wasPending = previous?.isWordPending(word) ?? false;
      if (wasPending && !next.isWordPending(word) && _isWaitingForBatch) {
        _loadAiResult();
      }
    });

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('单词详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_word == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('单词详情')),
        body: const Center(child: Text('单词不存在')),
      );
    }

    final word = _word!;
    final colorScheme = Theme.of(context).colorScheme;
    final genderColor = GenderColors.forArticle(word.article);
    // 释义/例句展示条件（优先AI完整结果，与查词界面一致）
    final hasDefinitions = (_aiResult?.definitions.isNotEmpty ?? false) ||
        word.chinese.isNotEmpty;
    final hasExamples = (_aiResult?.examples.isNotEmpty ?? false) ||
        (word.example != null && word.example!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('单词详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 单词头部（与查词界面一致）
            _buildWordHeader(word, genderColor, colorScheme),
            const SizedBox(height: 16),
            // 释义（优先AI完整结果，与查词界面一致）
            if (hasDefinitions)
              _buildDefinitionsCard(word, _aiResult, colorScheme),
            if (hasDefinitions) const SizedBox(height: 16),
            // 变格/变位（与 AI 查词界面同款样式：缓存优先，回退 words 表字段）
            if (word.wordType == 'verb' ||
                word.wordType == 'noun' ||
                word.wordType == 'adjective') ...[
              _buildInflectionCard(word),
              const SizedBox(height: 16),
            ],
            // 动词搭配
            if (_aiResult?.collocations != null &&
                _aiResult!.collocations!.isNotEmpty) ...[
              _buildCollocations(_aiResult!, colorScheme),
              const SizedBox(height: 16),
            ],
            // 例句（优先AI完整结果，与查词界面一致）
            if (hasExamples)
              _buildExamplesCard(word, _aiResult, colorScheme),
            if (hasExamples) const SizedBox(height: 16),
            // AI 解析
            if (_aiResult?.aiAnalysis != null) ...[
              _buildAiAnalysisCard(_aiResult!, colorScheme),
              const SizedBox(height: 16),
            ],
            // AI 加载中提示
            if (_isLoadingAi)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('AI 深度解析加载中...'),
                    ],
                  ),
                ),
              ),
            if (_isLoadingAi) const SizedBox(height: 16),
            // 单词已在后台AI查询队列中的提示（任务完成后自动刷新）
            if (_isWaitingForBatch)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('该单词已在后台 AI 查询队列中，完成后将自动显示结果'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isWaitingForBatch) const SizedBox(height: 16),
            // 学习状态（学习次数，单词本特有）
            _buildLearningStatus(word),
            const SizedBox(height: 16),
            // 标签
            if (word.tags != null && word.tags!.isNotEmpty) _buildTags(word),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// 单词头部（与查词界面一致）
  Widget _buildWordHeader(
      Word word, Color genderColor, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 冠词标签
                if (word.article != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: genderColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      word.article!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: genderColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                // 单词
                Expanded(
                  child: Text(
                    word.baseForm ?? word.german,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                // 发音按钮
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _speak(word.baseForm ?? word.german),
                ),
              ],
            ),
            // 复数
            if (word.nounPlural != null) ...[
              const SizedBox(height: 8),
              Text(
                '复数: ${word.nounPlural}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            // 词性标签
            if (word.wordType != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '词性: ${WordTypeColors.getWordTypeDescription(word.wordType)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  WordTypeChip(
                    wordType: word.wordType,
                    article: word.article,
                    compact: true,
                    showLabel: false,
                  ),
                  // 名词可数/不可数标签
                  if (word.nounType != null) ...[
                    const SizedBox(width: 8),
                    NounTypeChip(nounType: word.nounType),
                  ],
                ],
              ),
            ],
            // 可分前缀
            if (_aiResult?.separablePrefix != null) ...[
              const SizedBox(height: 4),
              Text(
                '可分前缀: ${_aiResult!.separablePrefix}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            // 基础动词
            if (_aiResult?.baseVerb != null) ...[
              const SizedBox(height: 4),
              Text(
                '基础动词: ${_aiResult!.baseVerb}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 释义卡片（优先展示AI完整释义列表，与查词界面一致）
  Widget _buildDefinitionsCard(
      Word word, DictionaryResult? aiResult, ColorScheme colorScheme) {
    final definitions = aiResult?.definitions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '释义',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (definitions != null && definitions.isNotEmpty)
              ...definitions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${entry.key + 1}. ${entry.value}'),
                );
              })
            else
              Text(word.chinese),
          ],
        ),
      ),
    );
  }

  /// 例句卡片（优先展示AI完整例句列表，与查词界面一致）
  Widget _buildExamplesCard(
      Word word, DictionaryResult? aiResult, ColorScheme colorScheme) {
    final examples = aiResult?.examples;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '例句',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (examples != null && examples.isNotEmpty)
              ...examples.map((example) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    example,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                );
              })
            else
              Text(
                word.example!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  /// 动词搭配（与查词界面一致）
  Widget _buildCollocations(DictionaryResult result, ColorScheme colorScheme) {
    return Card(
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: color.withValues(alpha: 0.3)),
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
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
                const Text('四格 (Akkusativ)',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// AI 解析卡片
  Widget _buildAiAnalysisCard(
      DictionaryResult result, ColorScheme colorScheme) {
    return Card(
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
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.aiAnalysis!),
          ],
        ),
      ),
    );
  }

  /// 变格/变位卡片（与 AI 查词界面同款样式：缓存优先，回退 words 表字段）
  Widget _buildInflectionCard(Word word) {
    final (String title, IconData icon) = switch (word.wordType) {
      'verb' => ('动词变位', Icons.auto_fix_high),
      'noun' => ('名词变格', Icons.category),
      'adjective' => ('形容词比较', Icons.trending_up),
      _ => ('变格', Icons.category),
    };
    final List<Widget> rows = switch (word.wordType) {
      'verb' => _buildVerbInflection(word),
      'noun' => _buildNounInflection(word),
      'adjective' => _buildAdjInflection(word),
      _ => <Widget>[],
    };
    return _buildSection(
      context,
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  /// 动词变位：缓存完整 6 人称优先，回退 words 表单值字段
  List<Widget> _buildVerbInflection(Word word) {
    const tenseMeta = [
      ('praesens', '现在时', 'Präsens'),
      ('praeteritum', '过去时', 'Präteritum'),
      ('perfekt', '完成时', 'Perfekt'),
      ('passiv', '被动态', 'Passiv'),
    ];
    final tenses = Inflection.verbTenses(_conjugationCache);
    if (tenses != null && tenses.isNotEmpty) {
      final perfektParts = Inflection.perfektParts(_conjugationCache);
      final widgets = <Widget>[];
      for (final (key, zh, de) in tenseMeta) {
        final persons = tenses[key];
        if (persons == null) continue;
        widgets.add(InflectionTenseBlock(
          zhLabel: zh,
          deLabel: de,
          header: key == 'perfekt' && (perfektParts.auxiliary != null ||
                  perfektParts.partizip != null)
              ? '${perfektParts.auxiliary ?? ''} ${perfektParts.partizip ?? ''}'
                  .trim()
              : null,
          persons: persons,
        ));
      }
      if (widgets.isNotEmpty) return widgets;
    }
    // 回退 words 表单值字段（与查词界面展示一致）
    return [
      if (word.verbPresent != null)
        InflectionRow(label: '现在时', value: word.verbPresent!),
      if (word.verbPast != null)
        InflectionRow(label: '过去时', value: word.verbPast!),
      if (word.verbPerfect != null)
        InflectionRow(label: '完成时', value: word.verbPerfect!),
      if (word.verbPresent == null &&
          word.verbPast == null &&
          word.verbPerfect == null)
        _buildNoInflectionHint(),
    ];
  }

  /// 名词变格：缓存优先，回退 words 表字段
  List<Widget> _buildNounInflection(Word word) {
    final noun = Inflection.nounParts(_conjugationCache);
    final genitiv = noun.genitiv ?? word.nounGenitive;
    final plural = noun.plural ?? word.nounPlural;
    return [
      if (genitiv != null) InflectionRow(label: '第二格', value: genitiv),
      if (plural != null) InflectionRow(label: '复数', value: plural),
      if (genitiv == null && plural == null) _buildNoInflectionHint(),
    ];
  }

  /// 形容词比较级/最高级：缓存优先，回退 words 表字段
  List<Widget> _buildAdjInflection(Word word) {
    final adj = Inflection.adjParts(_conjugationCache);
    final comparative = adj.komparativ ?? word.adjComparative;
    final superlative = adj.superlativ ?? word.adjSuperlative;
    return [
      if (comparative != null)
        InflectionRow(label: '比较级', value: comparative),
      if (superlative != null)
        InflectionRow(label: '最高级', value: superlative),
      if (comparative == null && superlative == null)
        _buildNoInflectionHint(),
    ];
  }

  /// 无变格数据时的提示
  Widget _buildNoInflectionHint() {
    return Text(
      '暂无变格数据（可在 AI 查词中获取）',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildLearningStatus(Word word) {
    final sm2 = _sm2State;
    final nextReview = sm2?.nextReview;
    final now = DateTime.now();
    final isDue = nextReview != null && nextReview.isBefore(now);

    return _buildSection(
      context,
      title: '学习状态',
      icon: Icons.school,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(
                label: '复习次数',
                value: '${sm2?.totalReviews ?? 0}',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: '连续正确',
                value: '${sm2?.correctStreak ?? 0}',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (sm2 != null) ...[
            Text(
              '简易度: ${sm2.easeFactor.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '复习间隔: ${sm2.intervalDays.toStringAsFixed(0)} 天',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (nextReview != null) ...[
            const SizedBox(height: 4),
            Text(
              isDue ? '已到期，需要复习' : '下次复习: ${_formatDate(nextReview)}',
              style: TextStyle(
                color: isDue ? Colors.red : Colors.grey,
                fontWeight:
                    isDue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTags(Word word) {
    final tags = word.tags!.split(',').map((e) => e.trim()).toList();

    return _buildSection(
      context,
      title: '标签',
      icon: Icons.label,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags
            .map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 显示编辑对话框
  void _showEditDialog(BuildContext context) {
    if (_word == null) return;
    showDialog(
      context: context,
      builder: (context) => _EditWordDialog(
        word: _word!,
        aiResult: _aiResult,
        onSaved: (updatedWord) {
          setState(() {
            _word = updatedWord;
          });
        },
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(BuildContext context) {
    if (_word == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除单词'),
        content: Text('确定要删除 "${_word!.german}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              if (db != null) {
                await db.wordDao.deleteWord(_word!.id);
              }
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 编辑单词对话框
class _EditWordDialog extends ConsumerStatefulWidget {
  final Word word;
  final DictionaryResult? aiResult;
  final Function(Word) onSaved;

  const _EditWordDialog({
    required this.word,
    this.aiResult,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditWordDialog> createState() => _EditWordDialogState();
}

class _EditWordDialogState extends ConsumerState<_EditWordDialog> {
  late TextEditingController _germanController;
  late TextEditingController _chineseController;
  late TextEditingController _exampleController;
  late TextEditingController _tagsController;
  late TextEditingController _articleController;
  String? _selectedWordType;
  String? _selectedNounType;
  bool _isSaving = false;

  /// 下拉框支持的词性集合，避免脏值触发 DropdownButton 断言崩溃
  static const _supportedWordTypes = {'noun', 'verb', 'adjective', 'adverb', 'other'};
  /// 下拉框支持的名词类型集合
  static const _supportedNounTypes = {'countable', 'uncountable', 'both'};

  @override
  void initState() {
    super.initState();
    final ai = widget.aiResult;
    // 优先使用AI解析结果（与详情页展示一致），无AI结果时回退words表
    _germanController = TextEditingController(text: widget.word.german);
    _chineseController = TextEditingController(
      text: (ai != null && ai.definitions.isNotEmpty)
          ? ai.definitions.join('\n')
          : widget.word.chinese,
    );
    _exampleController = TextEditingController(
      text: (ai != null && ai.examples.isNotEmpty)
          ? ai.examples.join('\n')
          : widget.word.example ?? '',
    );
    _tagsController =
        TextEditingController(text: widget.word.tags ?? '');
    _articleController = TextEditingController(
      text: (ai != null && ai.article != null)
          ? ai.article!
          : widget.word.article ?? '',
    );
    // 词性/名词类型必须在下拉框支持集合内，否则 Dropdown 断言崩溃
    final aiWordType = ai?.partOfSpeech;
    _selectedWordType = _supportedWordTypes.contains(aiWordType)
        ? aiWordType
        : (_supportedWordTypes.contains(widget.word.wordType)
            ? widget.word.wordType
            : null);
    final aiNounType = ai?.nounType;
    _selectedNounType = _supportedNounTypes.contains(aiNounType)
        ? aiNounType
        : (_supportedNounTypes.contains(widget.word.nounType)
            ? widget.word.nounType
            : null);
  }

  @override
  void dispose() {
    _germanController.dispose();
    _chineseController.dispose();
    _exampleController.dispose();
    _tagsController.dispose();
    _articleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑单词'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 德语
            TextField(
              controller: _germanController,
              decoration: const InputDecoration(
                labelText: '德语',
                hintText: '例如: das Haus',
              ),
            ),
            const SizedBox(height: 12),
            // 冠词
            TextField(
              controller: _articleController,
              decoration: const InputDecoration(
                labelText: '冠词',
                hintText: 'der/die/das',
              ),
            ),
            const SizedBox(height: 12),
            // 中文释义
            TextField(
              controller: _chineseController,
              decoration: const InputDecoration(
                labelText: '中文释义',
                hintText: '例如: 房子',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            // 词性选择
            DropdownButtonFormField<String>(
              value: _selectedWordType,
              decoration: const InputDecoration(labelText: '词性'),
              items: const [
                DropdownMenuItem(value: 'noun', child: Text('名词')),
                DropdownMenuItem(value: 'verb', child: Text('动词')),
                DropdownMenuItem(
                    value: 'adjective', child: Text('形容词')),
                DropdownMenuItem(value: 'adverb', child: Text('副词')),
                DropdownMenuItem(value: 'other', child: Text('其他')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedWordType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            // 名词类型（仅名词显示）
            if (_selectedWordType == 'noun')
              DropdownButtonFormField<String>(
                value: _selectedNounType,
                decoration: const InputDecoration(labelText: '名词类型'),
                items: const [
                  DropdownMenuItem(
                      value: 'countable', child: Text('可数 (C)')),
                  DropdownMenuItem(
                      value: 'uncountable', child: Text('不可数 (U)')),
                  DropdownMenuItem(
                      value: 'both', child: Text('可数/不可数 (C/U)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedNounType = value;
                  });
                },
              ),
            if (_selectedWordType == 'noun') const SizedBox(height: 12),
            // 例句
            TextField(
              controller: _exampleController,
              decoration: const InputDecoration(
                labelText: '例句',
                hintText: '例如: Das Haus ist groß.',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            // 标签
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '多个标签用逗号分隔',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    final db = ref.read(databaseProvider);
    if (db == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final german = _germanController.text.trim();
    final chinese = _chineseController.text.trim();
    if (german.isEmpty || chinese.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('德语和中文不能为空')),
        );
      }
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      // 解析德语获取 baseForm
      final baseForm = german.contains(' ')
          ? german.split(' ').last
          : german;

      await db.wordDao.updateWord(
        WordsCompanion(
          id: drift.Value(widget.word.id),
          german: drift.Value(german),
          article: drift.Value(
              _articleController.text.trim().isEmpty
                  ? null
                  : _articleController.text.trim()),
          baseForm: drift.Value(baseForm),
          wordType: drift.Value(_selectedWordType),
          chinese: drift.Value(chinese),
          example: drift.Value(
              _exampleController.text.trim().isEmpty
                  ? null
                  : _exampleController.text.trim()),
          tags: drift.Value(
              _tagsController.text.trim().isEmpty
                  ? null
                  : _tagsController.text.trim()),
          nounType: drift.Value(_selectedNounType),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // 重新加载数据
      final updatedWord = await db.wordDao.getWordById(widget.word.id);
      if (updatedWord != null) {
        widget.onSaved(updatedWord);
      }

      // 保存后同步更新AI缓存，保证详情页展示与编辑内容一致
      try {
        final cached = await db.aiCacheDao.getCachedResult(widget.word.german);
        if (cached != null) {
          final data = jsonDecode(cached.resultJson) as Map<String, dynamic>;
          data['definitions'] = chinese
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          final exampleText = _exampleController.text.trim();
          data['examples'] = exampleText.isEmpty
              ? <String>[]
              : exampleText
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
          data['article'] = _articleController.text.trim().isEmpty
              ? null
              : _articleController.text.trim();
          data['part_of_speech'] = _selectedWordType;
          data['noun_type'] = _selectedNounType;
          await db.aiCacheDao.saveToCache(
            word: widget.word.german,
            resultJson: jsonEncode(data),
          );
        }
      } catch (e) {
        debugPrint('同步更新AI缓存失败: $e');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
