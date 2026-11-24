import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_localizations.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/training_provider.dart';
import '../../services/dictionary/dictionary_engine.dart';
import '../../services/dictionary/word_intake_service.dart';

/// 语境查词底部弹窗（任务书 §6.1）
///
/// 与「联网查词」页的区别：把**选中文本 + 所在句子 + 前后文 + 材料等级**
/// 一起传给引擎，让 AI 解释"这个词在这个句子里的意思"；
/// 入库走 [WordIntakeService]，与查词页共用同一套规则（不重复建词、不重置 SM-2）。
class ContextLookupSheet extends ConsumerStatefulWidget {
  final String selectedText;
  final String? sentence;
  final String? surroundingContext;
  final String? cefrLevel;

  const ContextLookupSheet({
    super.key,
    required this.selectedText,
    this.sentence,
    this.surroundingContext,
    this.cefrLevel,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedText,
    String? sentence,
    String? surrounding,
    String? cefrLevel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ContextLookupSheet(
        selectedText: selectedText,
        sentence: sentence,
        surroundingContext: surrounding,
        cefrLevel: cefrLevel,
      ),
    );
  }

  @override
  ConsumerState<ContextLookupSheet> createState() => _ContextLookupSheetState();
}

class _ContextLookupSheetState extends ConsumerState<ContextLookupSheet> {
  DictionaryResult? _result;
  bool _loading = true;
  String? _error;
  WordIntakeResult? _existing;
  List<Deck> _decks = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
  }

  Future<void> _lookup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lookupContext = LookupContext(
        selectedText: widget.selectedText,
        sentence: widget.sentence,
        context: widget.surroundingContext,
        cefrLevel: widget.cefrLevel,
      );

      final settings = ref.read(settingsProvider);
      DictionaryEngine? engine;
      if (settings.aiConfig.isConfigured) {
        engine = ref.read(aiDictionaryEngineProvider);
      } else {
        engine = switch (ref.read(selectedEngineProvider)) {
          DictionaryEngineType.wiktionary => ref.read(wiktionaryEngineProvider),
          DictionaryEngineType.godic => ref.read(godicEngineProvider),
          DictionaryEngineType.ai => null,
        };
      }

      if (engine == null) {
        setState(() {
          _loading = false;
          _error = context.tr('请先在设置中配置 AI API Key');
        });
        return;
      }

      final result = await engine.lookup(
        widget.selectedText,
        context: lookupContext,
      );
      final db = ref.read(databaseProvider);
      WordIntakeResult? existing;
      List<Deck> decks = const [];
      if (db != null) {
        decks = await db.deckDao.getAllDecks();
        if (result != null) {
          existing = await WordIntakeService(db).findExisting(result);
        }
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _existing = existing;
        _decks = decks;
        _loading = false;
        _error = result == null ? context.tr('未找到结果') : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.trArgs('查词失败: {0}', [e]);
      });
    }
  }

  Future<void> _speak() async {
    final service = ref.read(trainingSpeechProvider);
    if (!service.isInitialized) {
      await service.initialize(rate: ref.read(settingsProvider).ttsSpeed);
    }
    await service.speak(widget.selectedText);
  }

  Future<void> _addToDeck(int deckId) async {
    final db = ref.read(databaseProvider);
    final result = _result;
    if (db == null || result == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await WordIntakeService(db)
        .addToDeck(deckId: deckId, result: result);
    final existing = await WordIntakeService(db).findExisting(result);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _existing = existing;
    });
    messenger.showSnackBar(SnackBar(
      content: Text(
        outcome.isAdded
            ? context.tr('已添加到词书')
            : outcome.status == WordIntakeStatus.alreadyExists
                ? context.tr('该单词已存在，未重复添加')
                : context.tr('添加失败'),
      ),
    ));
  }

  Future<void> _toggleFavorite() async {
    final db = ref.read(databaseProvider);
    final word = _existing?.existingWord;
    if (db == null || word == null) return;
    setState(() => _busy = true);
    await db.wordDao.updateFavorite(word.id, !word.isFavorite);
    final refreshed = await db.wordDao.getWordById(word.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _existing = refreshed == null
          ? _existing
          : WordIntakeResult(
              status: WordIntakeStatus.alreadyExists,
              existingWord: refreshed,
              existingDeck: _existing?.existingDeck,
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部把手 + 选中词
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectedText,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.sentence != null &&
                            widget.sentence!.isNotEmpty)
                          Text(
                            context.tr('已结合所在句子解析'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _speak,
                    icon: const Icon(Icons.volume_up),
                    tooltip: context.tr('发音'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: context.tr('关闭'),
                  ),
                ],
              ),
            ),
            if (widget.sentence != null && widget.sentence!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.sentence!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _lookup,
              child: Text(context.tr('重试')),
            ),
          ],
        ),
      );
    }

    final result = _result;
    if (result == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 词条基础信息
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if ((result.article ?? '').isNotEmpty)
              Chip(label: Text(result.article!)),
            if ((result.partOfSpeech ?? '').isNotEmpty)
              Chip(label: Text(result.partOfSpeech!)),
            if ((result.plural ?? '').isNotEmpty)
              Chip(label: Text('Pl. ${result.plural}')),
          ],
        ),
        const SizedBox(height: 12),
        for (final definition in result.definitions)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('· '),
                Expanded(
                  child: Text(definition, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        if ((result.aiAnalysis ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            result.aiAnalysis!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (result.examples.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.tr('例句'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          for (final example in result.examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(example, style: theme.textTheme.bodyMedium),
            ),
        ],
        const SizedBox(height: 16),
        _buildActions(context),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final existingWord = _existing?.existingWord;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (existingWord != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 18, color: colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _existing?.existingDeck == null
                        ? context.tr('该单词已在词书中')
                        : context.trArgs(
                            '已在词书「{0}」',
                            [_existing!.existingDeck!.name],
                          ),
                    style: TextStyle(color: colorScheme.onSecondaryContainer),
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _toggleFavorite,
                  icon: Icon(
                    existingWord.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text(
                    existingWord.isFavorite
                        ? context.tr('取消收藏')
                        : context.tr('收藏'),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text(
            context.tr('加入词书'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (_decks.isEmpty)
            Text(
              context.tr('还没有词书，请先创建一个词书'),
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final deck in _decks)
                  ActionChip(
                    avatar: const Icon(Icons.library_books_outlined, size: 16),
                    label: Text(deck.name),
                    onPressed: _busy ? null : () => _addToDeck(deck.id),
                  ),
              ],
            ),
        ],
        const SizedBox(height: 8),
        Text(
          context.tr('查词结果与所在句子一并解析，加入词书后可在学习模式复习'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
