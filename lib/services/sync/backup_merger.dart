import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import '../../core/utils/german_parser.dart';
import '../../data/database/app_database.dart';

/// 同步冲突：同一单词在本地与云端都发生过修改，无法自动合并
class SyncConflict {
  /// 所属词书名称
  final String deckName;

  /// 德语单词
  final String german;

  /// 本地修改时间
  final DateTime? localUpdatedAt;

  /// 云端修改时间
  final DateTime? cloudUpdatedAt;

  const SyncConflict({
    required this.deckName,
    required this.german,
    this.localUpdatedAt,
    this.cloudUpdatedAt,
  });
}

/// 冲突解决方向
enum ConflictResolution { local, cloud }

/// 备份合并结果
class BackupMergeResult {
  /// 合并后的完整备份（可直接序列化上传或写库）
  final Map<String, dynamic> mergedBackup;

  /// 检测到的真冲突列表（resolution 为 null 时仅检测）
  final List<SyncConflict> conflicts;

  final int decksAdded;
  final int decksUpdated;
  final int wordsAdded;
  final int wordsUpdated;
  final int settingsMerged;
  final int cachesMerged;

  /// 合并结果与本地完全一致、无需写库的单词键（`词书名|德语原词`，均小写）。
  ///
  /// 供 [BackupMerger.applyToDatabase] 跳过无变化的单词写入：典型同步里绝大多数
  /// 单词两端一致，跳过可避免每次同步全量重写所有单词。
  final Set<String> unchangedWordKeys;

  /// 合并结果与本地完全一致、无需写库的 AI 缓存条目键（`word|engine`）。
  final Set<String> unchangedAiCacheKeys;

  const BackupMergeResult({
    required this.mergedBackup,
    required this.conflicts,
    required this.decksAdded,
    required this.decksUpdated,
    required this.wordsAdded,
    required this.wordsUpdated,
    required this.settingsMerged,
    required this.cachesMerged,
    this.unchangedWordKeys = const {},
    this.unchangedAiCacheKeys = const {},
  });

  bool get hasConflicts => conflicts.isNotEmpty;
}

/// 备份差异合并器
///
/// 以「备份 JSON v4」为数据载体，将本地与云端备份做三向合并：
/// - 词书按名称匹配、单词按 (词书, 德语原词) 匹配（与词书内查重规则一致）
/// - 仅一侧存在的数据直接并入（只增不删，避免误删任何设备的学习数据）
/// - 两侧都存在时按各自 updatedAt 时间戳“新者胜”合并内容与学习进度；
///   收藏（isFavorite）取并集，每日错误统计按日期取较大值
/// - 同一单词两端都修改过（本地晚于云端备份导出时间、云端晚于上次同步时间）
///   判定为真冲突，交由用户选择方向，绝不静默覆盖
class BackupMerger {
  BackupMerger._();

  /// 本地记录上次同步时间的设置键（合并时排除，避免两端互相同步该键）
  static const String lastSyncKey = 'onedrive_lastSyncAt';

  /// 三向合并本地与云端备份
  ///
  /// [lastSyncAt] 为本地记录的上次成功同步时间；
  /// [resolution] 为 null 时只检测冲突不应用（合并结果仅供读取 conflicts），
  /// 非 null 时冲突项按指定方向取整条数据。
  static BackupMergeResult merge({
    required Map<String, dynamic> local,
    required Map<String, dynamic> cloud,
    DateTime? lastSyncAt,
    ConflictResolution? resolution,
  }) {
    final conflicts = <SyncConflict>[];
    var decksAdded = 0;
    var decksUpdated = 0;
    var wordsAdded = 0;
    var wordsUpdated = 0;
    // 合并后与本地完全一致、无需写库的单词键（供 applyToDatabase 跳过写入）
    final unchangedWordKeys = <String>{};

    final cloudExportedAt = _parseDate(cloud['exportedAt']);
    final localDecks = _indexDecks(local['decks']);
    final cloudDecks = _indexDecks(cloud['decks']);
    final deckNames = {...localDecks.keys, ...cloudDecks.keys}.toList()..sort();

    // 墓碑合并：两端删除记录并集，同键取删除时间较晚者
    // （词书键 german 为空串；删除后对端仍活动/重建的墓碑会被作废移除）
    final tombstones = _mergeTombstones(
      _indexTombstones(local['deletions']),
      _indexTombstones(cloud['deletions']),
    );

    final mergedDecks = <Map<String, dynamic>>[];
    for (final name in deckNames) {
      final lDeck = localDecks[name];
      final cDeck = cloudDecks[name];

      // 词书级墓碑：整词书删除后两端均无活动才剔除；否则作废墓碑
      final deckTomb = tombstones['${name.toLowerCase()}|'];
      if (deckTomb != null) {
        final deletedAt = _parseDate(deckTomb['deletedAt']);
        if (deletedAt != null) {
          final lActive =
              lDeck == null ? DateTime(0) : _deckLastActivity(lDeck);
          final cActive =
              cDeck == null ? DateTime(0) : _deckLastActivity(cDeck);
          final maxActive = lActive.isAfter(cActive) ? lActive : cActive;
          if (maxActive.isBefore(deletedAt)) {
            // 词书删除后两端均无活动 → 整词书（含全部单词）剔除，墓碑保留传播
            continue;
          }
          // 删除后对端仍在学习/编辑该词书 → 词书保留，墓碑作废
          tombstones.remove('${name.toLowerCase()}|');
        }
      }

      // 仅云端有：整词书并入（先按词级墓碑过滤，剔除删除后无活动的词）
      if (lDeck == null) {
        final cloudWords =
            _filterTombstonedWords(name, cDeck!['words'], tombstones);
        mergedDecks.add({...cDeck, 'words': cloudWords});
        decksAdded++;
        wordsAdded += cloudWords.length;
        continue;
      }
      // 仅本地有：保留本地版本（同步只增不删；同样过滤墓碑命中的词）
      if (cDeck == null) {
        final localWords =
            _filterTombstonedWords(name, lDeck['words'], tombstones);
        mergedDecks.add({...lDeck, 'words': localWords});
        // 本地独有的词已存在于本地库，整批标记为无需写库
        for (final w in localWords) {
          final g = w['german']?.toString().trim() ?? '';
          if (g.isNotEmpty) unchangedWordKeys.add(_wordKey(name, g));
        }
        continue;
      }

      // 两侧同名词书：合并单词
      final lWords = _indexWords(lDeck['words']);
      final cWords = _indexWords(cDeck['words']);
      final wordKeys = {...lWords.keys, ...cWords.keys}.toList()..sort();
      final mergedWords = <Map<String, dynamic>>[];
      for (final german in wordKeys) {
        final lw = lWords[german];
        final cw = cWords[german];

        // 词级墓碑：删除后对端仍活动/重建 → 保留并作废墓碑；
        // 两端均无活动 → 剔除该词（墓碑保留继续传播）
        final tomb = tombstones['${name.toLowerCase()}|$german'];
        if (tomb != null) {
          final deletedAt = _parseDate(tomb['deletedAt']);
          if (deletedAt != null) {
            final lRes = lw != null && _resurrected(lw, deletedAt);
            final cRes = cw != null && _resurrected(cw, deletedAt);
            if (lRes || cRes) {
              tombstones.remove('${name.toLowerCase()}|$german');
            } else {
              continue;
            }
          }
        }

        if (lw == null) {
          mergedWords.add(cw!);
          wordsAdded++;
          continue;
        }
        if (cw == null) {
          // 仅本地有：本地库已是该内容，标记为无需写库
          mergedWords.add(lw);
          final g = lw['german']?.toString().trim() ?? german;
          if (g.isNotEmpty) unchangedWordKeys.add(_wordKey(name, g));
          continue;
        }
        // 索引键为小写（查重规则），但冲突提示应使用单词原始拼写（如 Haus）
        final displayGerman = (lw['german'] ?? cw['german'] ?? german)
            .toString();
        // 词书名索引键为小写，冲突提示使用原始大小写（此处分支 lDeck 必非空）
        final displayDeckName = lDeck['name']?.toString() ?? name;
        final merged = _mergeWord(
          displayDeckName,
          displayGerman,
          lw,
          cw,
          cloudExportedAt,
          lastSyncAt,
          resolution,
          conflicts,
        );
        if (merged.$2) {
          wordsUpdated++;
        } else {
          // 合并结果与本地逐字段一致 → 无需写库
          unchangedWordKeys.add(_wordKey(name, displayGerman));
        }
        mergedWords.add(merged.$1);
      }
      mergedDecks.add(_mergeDeckMeta(lDeck, cDeck, mergedWords));
      decksUpdated++;
    }

    // AI 查词缓存 / 设置：按键合并，时间戳新者胜
    // （AI 请求状态 aiStatus 是设备本地日志，不参与同步，故此处不合并）
    final unchangedAiCacheKeys = <String>{};
    final mergedAiCache = _mergeByTimestamp(
      local['aiCache'],
      cloud['aiCache'],
      'updatedAt',
      unchangedKeys: unchangedAiCacheKeys,
    );
    final mergedSettings = _mergeSettings(local['settings'], cloud['settings']);

    var wordCount = 0;
    for (final d in mergedDecks) {
      final ws = d['words'];
      if (ws is List) wordCount += ws.length;
    }

    // 保留的墓碑（作废的已移除）：按删除时间排序，上限 500 条防无限增长
    final mergedDeletions = tombstones.values.toList()
      ..sort((a, b) => (_parseDate(a['deletedAt']) ?? DateTime(0))
          .compareTo(_parseDate(b['deletedAt']) ?? DateTime(0)));
    if (mergedDeletions.length > 500) {
      mergedDeletions.removeRange(0, mergedDeletions.length - 500);
    }

    final mergedBackup = <String, dynamic>{
      ...cloud,
      'exportedAt': DateTime.now().toIso8601String(),
      'decks': mergedDecks,
      'deckCount': mergedDecks.length,
      'wordCount': wordCount,
      'aiCache': mergedAiCache,
      'aiCacheCount': mergedAiCache.length,
      'settings': mergedSettings,
      'settingsCount': mergedSettings.length,
      'deletions': mergedDeletions,
      'deletionCount': mergedDeletions.length,
    };

    return BackupMergeResult(
      mergedBackup: mergedBackup,
      conflicts: conflicts,
      decksAdded: decksAdded,
      decksUpdated: decksUpdated,
      wordsAdded: wordsAdded,
      wordsUpdated: wordsUpdated,
      settingsMerged: mergedSettings.length,
      cachesMerged: mergedAiCache.length,
      unchangedWordKeys: unchangedWordKeys,
      unchangedAiCacheKeys: unchangedAiCacheKeys,
    );
  }

  /// 单词去重键：`词书名|德语原词`，均小写（与词书/单词索引规则一致）
  static String _wordKey(String deckName, String german) =>
      '${deckName.trim().toLowerCase()}|${german.trim().toLowerCase()}';

  /// 将合并结果增量写入本地数据库（upsert 语义，不清空任何现有数据）
  ///
  /// 词书按名称匹配、单词按词书内德语原词匹配：存在则更新，不存在则创建。
  ///
  /// [unchangedWordKeys] / [unchangedAiCacheKeys] 为合并阶段算好的「与本地完全
  /// 一致」的单词 / AI 缓存条目键（见 [BackupMergeResult]）；命中则跳过写库，
  /// 避免每次同步把整本书的单词与全部 AI 缓存重写一遍。
  static Future<void> applyToDatabase(
    AppDatabase db,
    Map<String, dynamic> merged, {
    Set<String> unchangedWordKeys = const {},
    Set<String> unchangedAiCacheKeys = const {},
  }) async {
    final decks = merged['decks'];
    if (decks is! List) return;

    await db.transaction(() async {
      final existingDecks = await db.deckDao.getAllDecks();
      // 词书名（小写）→ 词书 ID；新创建的词书也会写入，供激活兜底与墓碑删除查找
      final deckIdByName = {
        for (final d in existingDecks) d.name.trim().toLowerCase(): d.id,
      };
      // 激活词书兜底：合并结果可能跨词书出现多个激活标记，取第一个
      String? activeDeckName;

      for (final deckJson in decks) {
        if (deckJson is! Map<String, dynamic>) continue;
        final name = deckJson['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;

        final existingId = deckIdByName[name.toLowerCase()];
        final now = DateTime.now();
        final createdAt = _parseDate(deckJson['createdAt']) ?? now;
        final updatedAt = _parseDate(deckJson['updatedAt']) ?? now;
        final description = deckJson['description']?.toString();
        final isActive = deckJson['isActive'] == true;
        if (isActive) activeDeckName = name;

        int deckId;
        if (existingId != null) {
          // 名称保留本地现有写法（用户可能重命名过，仅首字母大小写差异等）
          deckId = existingId;
          final existingDeck =
              await db.deckDao.getDeckById(existingId);
          await db.deckDao.updateDeck(
            DecksCompanion(
              id: drift.Value(deckId),
              name: drift.Value(existingDeck?.name ?? name),
              description: drift.Value(description),
              isActive: drift.Value(isActive),
              createdAt: drift.Value(existingDeck?.createdAt ?? createdAt),
              updatedAt: drift.Value(updatedAt),
            ),
          );
        } else {
          deckId = await db.deckDao.createDeck(
            DecksCompanion.insert(
              name: name,
              description: description == null || description.isEmpty
                  ? const drift.Value.absent()
                  : drift.Value(description),
              isActive: drift.Value(isActive),
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );
          deckIdByName[name.toLowerCase()] = deckId;
        }

        final words = deckJson['words'];
        if (words is! List) continue;
        // 词书内规范化查重索引：构建一次 O(n)，避免 _applyWord 逐词全表扫描
        // 导致的 O(n²)（数千词时可达分钟级）。
        final canonicalIndex =
            await db.wordDao.canonicalKeyIndexInDeck(deckId);
        for (final w in words) {
          if (w is! Map<String, dynamic>) continue;
          // 合并结果与本地逐字段一致 → 跳过写库（典型同步的绝大多数单词）
          if (unchangedWordKeys.isNotEmpty) {
            final g = w['german']?.toString().trim() ?? '';
            if (g.isNotEmpty &&
                unchangedWordKeys.contains(_wordKey(name, g))) {
              continue;
            }
          }
          await _applyWord(db, deckId, w, canonicalIndex);
        }
      }

      // 唯一激活兜底（仅当合并结果中存在激活词书时；否则保留本地现状）
      if (activeDeckName != null) {
        final activeId = deckIdByName[activeDeckName.toLowerCase()];
        if (activeId != null) {
          await db.deckDao.setActiveDeck(activeId);
        }
      }

      // AI 查词缓存（保留合并后的时间戳；与本地一致的条目跳过写库）
      final aiCache = merged['aiCache'];
      if (aiCache is List) {
        for (final entry in aiCache) {
          if (entry is! Map<String, dynamic>) continue;
          final word = entry['word']?.toString() ?? '';
          final resultJson = entry['resultJson']?.toString() ?? '';
          if (word.isEmpty || resultJson.isEmpty) continue;
          // 合并键与 _mergeByTimestamp 一致：`word|engine`
          if (unchangedAiCacheKeys.contains('${entry['word']}|${entry['engine']}')) {
            continue;
          }
          final now = DateTime.now();
          final entryUpdated = _parseDate(entry['updatedAt']) ?? now;
          await db.into(db.aiLookupCache).insert(
            AiLookupCacheCompanion.insert(
              word: word,
              resultJson: resultJson,
              engine: drift.Value(entry['engine']?.toString() ?? 'ai'),
              createdAt: _parseDate(entry['createdAt']) ?? now,
              updatedAt: entryUpdated,
            ),
            onConflict: drift.DoUpdate(
              (old) => AiLookupCacheCompanion(
                resultJson: drift.Value(resultJson),
                updatedAt: drift.Value(entryUpdated),
              ),
              target: [db.aiLookupCache.word, db.aiLookupCache.engine],
            ),
          );
        }
      }

      // 设置（跳过同步内部键，避免两端互相同步）
      final settings = merged['settings'];
      if (settings is List) {
        for (final entry in settings) {
          if (entry is! Map<String, dynamic>) continue;
          final key = entry['key']?.toString() ?? '';
          if (key.isEmpty || key == lastSyncKey) continue;
          final value = entry['value']?.toString();
          if (value == null) continue;
          final entryUpdated = _parseDate(entry['updatedAt']);
          await db.into(db.settings).insert(
            SettingsCompanion.insert(
              key: key,
              value: value,
              updatedAt: entryUpdated ?? DateTime.now(),
            ),
            onConflict: drift.DoUpdate(
              (old) => SettingsCompanion(
                value: drift.Value(value),
                updatedAt: drift.Value(entryUpdated ?? DateTime.now()),
              ),
              target: [db.settings.key],
            ),
          );
        }
      }

      // 删除墓碑应用：合并结果中已剔除的词/词书，从本地库真正删除
      // （删除不写新墓碑——墓碑已在合并结果中，稍后由同步流程统一写回）
      final deletions = merged['deletions'];
      if (deletions is List) {
        // 删除查找用的「规范化词形 → 单词」索引按词书惰性构建、复用，
        // 避免每条墓碑都全表扫描一次（墓碑上限 500 条时的 O(n²)）。
        final deleteIndexByDeck = <int, Map<String, Word>>{};
        for (final d in deletions) {
          if (d is! Map<String, dynamic>) continue;
          final deckName = d['deck']?.toString().trim() ?? '';
          final german = d['german']?.toString() ?? '';
          if (deckName.isEmpty) continue;
          final deckId = deckIdByName[deckName.toLowerCase()];
          if (deckId == null) continue;
          if (german.isEmpty) {
            // 词书级删除（含其下全部单词与关联数据）
            await db.deckDao.deleteDeckInternal(deckId);
            deleteIndexByDeck.remove(deckId);
          } else {
            final index = deleteIndexByDeck[deckId] ??=
                await db.wordDao.germanIndexInDeck(deckId);
            // 墓碑按“德语原词精确匹配”（不做规范化），避免误删规范化词形相同的保留词
            final key = german.trim().toLowerCase();
            final word = key.isEmpty ? null : index[key];
            if (word != null) {
              await db.deleteWordInternal(word);
              index.remove(key);
            }
          }
        }
      }
    });
  }

  /// 合并单个单词（返回 (合并结果, 是否发生更新)）
  ///
  /// 双通道 LWW（Last-Write-Wins）：
  /// - 学习通道（proficiency/lastStudyDate/sm2）：以学习状态时间戳新者胜，
  ///   跨端复习进度静默合并、永不弹窗；
  /// - 内容通道（chinese/example/tags/变形等）：以单词 updatedAt 新者胜，
  ///   仅当两端在各自同步窗口内都编辑过且内容不同才判定冲突弹窗；
  /// - 收藏取并集，每日统计按日期取较大值，缓存内容相同则跳过。
  static (Map<String, dynamic>, bool) _mergeWord(
    String deckName,
    String german,
    Map<String, dynamic> lw,
    Map<String, dynamic> cw,
    DateTime? cloudExportedAt,
    DateTime? lastSyncAt,
    ConflictResolution? resolution,
    List<SyncConflict> conflicts,
  ) {
    final lUpdated = _parseDate(lw['updatedAt']);
    final cUpdated = _parseDate(cw['updatedAt']);

    // ===== 学习通道：复习进度按学习状态时间戳静默新者胜（永不弹窗）=====
    final studyWinner =
        _studyTimestamp(cw).isAfter(_studyTimestamp(lw)) ? cw : lw;

    // ===== 内容通道：两端都编辑过词义内容且内容不同才判定冲突 =====
    // 锚点取「上次成功同步时间」：两端都在对齐点之后编辑过才判冲突。
    // （不能用云端备份导出时间做本地侧锚点——云端导出时间会随对端每次
    //   同步而前进，导致“对端在我编辑后先上传”时漏判冲突、本地编辑被
    //   静默覆盖而不弹窗。）
    // 首次同步（无锚点）时退化为云端备份导出时间，两端都不判为“已变更”，
    // 按纯 LWW 合并，避免首次同步把全部内容都弹成冲突。
    final anchor = lastSyncAt ?? cloudExportedAt;
    final localContentChanged =
        lUpdated != null && anchor != null && lUpdated.isAfter(anchor);
    final cloudContentChanged =
        cUpdated != null && anchor != null && cUpdated.isAfter(anchor);
    final isConflict =
        localContentChanged && cloudContentChanged && _contentDiffers(lw, cw);

    Map<String, dynamic> contentWinner;
    if (isConflict) {
      conflicts.add(SyncConflict(
        deckName: deckName,
        german: german,
        localUpdatedAt: lUpdated,
        cloudUpdatedAt: cUpdated,
      ));
      if (resolution == null) {
        // 仅检测阶段：以本地版本占位，调用方不应用
        return (lw, false);
      }
      // 冲突解决后：词义内容取用户选择的一侧，学习进度仍按学习通道合并
      contentWinner = resolution == ConflictResolution.local ? lw : cw;
    } else {
      contentWinner =
          (lUpdated ?? DateTime(0)).isAfter(cUpdated ?? DateTime(0)) ? lw : cw;
    }

    // 组装：词义内容取内容胜者，学习字段取学习胜者，其余按规则合并
    final merged = <String, dynamic>{...contentWinner};
    merged['proficiency'] = studyWinner['proficiency'];
    merged['lastStudyDate'] = studyWinner['lastStudyDate'];
    merged['sm2'] = studyWinner['sm2'];
    merged['isFavorite'] =
        (lw['isFavorite'] == true) || (cw['isFavorite'] == true);
    merged['createdAt'] = _earlierString(lw['createdAt'], cw['createdAt']);
    merged['updatedAt'] = _laterString(lw['updatedAt'], cw['updatedAt']);
    merged['stats'] = _mergeStats(lw['stats'], cw['stats']);
    merged['conjugation'] = _mergeCache(lw['conjugation'], cw['conjugation']);
    // 仅当合并结果确实与本地记录不同才计为“更新”（避免两端一致的单词被重复计数）
    return (merged, !_sameValue(merged, lw));
  }

  /// 深度比较两个值（Map/List/标量），用于判断合并结果是否真正发生变化。
  ///
  /// 比较前先剥离默认值（null / 空串 / 空列表 / 空 Map / false / 0），
  /// 避免合并时补齐的默认键（如 sm2/stats/isFavorite 缺省）被误判为差异。
  static bool _sameValue(dynamic a, dynamic b) {
    return _sameRaw(_stripDefaults(a), _stripDefaults(b));
  }

  static bool _sameRaw(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_sameRaw(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_sameRaw(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  /// 递归剥离默认/空值，使两端缺省字段一致可比
  static dynamic _stripDefaults(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isEmpty) return null;
    if (v is bool && !v) return null;
    if (v is num && v == 0) return null;
    if (v is List) {
      final out = <dynamic>[];
      for (final item in v) {
        final s = _stripDefaults(item);
        if (s != null) out.add(s);
      }
      return out.isEmpty ? null : out;
    }
    if (v is Map) {
      final out = <String, dynamic>{};
      v.forEach((k, val) {
        final s = _stripDefaults(val);
        if (s != null) out[k.toString()] = s;
      });
      return out.isEmpty ? null : out;
    }
    return v;
  }

  /// 学习状态时间戳：优先取 SM-2 状态的 updatedAt（复习必然更新它），
  /// 无 SM-2 状态时退化为单词 updatedAt
  static DateTime _studyTimestamp(Map<String, dynamic> w) {
    final sm2 = w['sm2'];
    if (sm2 is Map<String, dynamic>) {
      final t = _parseDate(sm2['updatedAt']);
      if (t != null) return t;
    }
    return _parseDate(w['updatedAt']) ?? DateTime(0);
  }

  /// 词义内容字段（编辑类字段；学习进度/统计/缓存不在此列）
  static const List<String> _contentFields = [
    'chinese', 'example', 'tags', 'article', 'baseForm', 'wordType',
    'verbPresent', 'verbPast', 'verbPerfect',
    'nounGenitive', 'nounPlural', 'nounType',
    'adjComparative', 'adjSuperlative',
  ];

  /// 两端词义内容是否不同（null 与空串视为相同）
  static bool _contentDiffers(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    for (final f in _contentFields) {
      if ((a[f]?.toString().trim() ?? '') != (b[f]?.toString().trim() ?? '')) {
        return true;
      }
    }
    return false;
  }

  /// 合并词书元信息（名称视为同一词书，不复制）
  static Map<String, dynamic> _mergeDeckMeta(
    Map<String, dynamic> lDeck,
    Map<String, dynamic> cDeck,
    List<Map<String, dynamic>> mergedWords,
  ) {
    final lUpdated = _parseDate(lDeck['updatedAt']);
    final cUpdated = _parseDate(cDeck['updatedAt']);
    final newerDeck = (lUpdated ?? DateTime(0)).isAfter(cUpdated ?? DateTime(0))
        ? lDeck
        : cDeck;
    final olderDeck = newerDeck == lDeck ? cDeck : lDeck;
    return {
      ...newerDeck,
      'description': newerDeck['description'] ?? olderDeck['description'],
      'createdAt': _earlierString(lDeck['createdAt'], cDeck['createdAt']),
      'updatedAt': _laterString(lDeck['updatedAt'], cDeck['updatedAt']),
      'words': mergedWords,
    };
  }

  /// 每日错误统计合并：同一日期取较大值（累加会导致两端重复计数）
  static List<Map<String, dynamic>> _mergeStats(
    dynamic localStats,
    dynamic cloudStats,
  ) {
    final byDate = <String, Map<String, dynamic>>{};
    for (final list in [localStats, cloudStats]) {
      if (list is! List) continue;
      for (final s in list) {
        if (s is! Map<String, dynamic>) continue;
        final date = s['date']?.toString();
        if (date == null) continue;
        final existing = byDate[date];
        if (existing == null) {
          byDate[date] = Map<String, dynamic>.of(s);
          continue;
        }
        existing['appearances'] = max(
          _parseInt(existing['appearances']),
          _parseInt(s['appearances']),
        );
        existing['errors'] = max(
          _parseInt(existing['errors']),
          _parseInt(s['errors']),
        );
      }
    }
    return byDate.values.toList();
  }

  /// 按唯一键 (word, engine) 合并列表，指定时间戳字段新者胜
  ///
  /// [unchangedKeys] 非空时，收集合并结果中与本地完全一致（无需写库）的条目键
  /// `word|engine`，供 [applyToDatabase] 跳过无变化的 AI 缓存写入。
  static List<Map<String, dynamic>> _mergeByTimestamp(
    dynamic localList,
    dynamic cloudList,
    String timeField, {
    Set<String>? unchangedKeys,
  }) {
    // 本地条目索引：用于判断合并结果是否与本地一致
    final localByKey = <String, Map<String, dynamic>>{};
    if (localList is List) {
      for (final e in localList) {
        if (e is! Map<String, dynamic>) continue;
        localByKey['${e['word']}|${e['engine']}'] = e;
      }
    }

    final merged = <String, Map<String, dynamic>>{};
    for (final list in [localList, cloudList]) {
      if (list is! List) continue;
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final key = '${e['word']}|${e['engine']}';
        final existing = merged[key];
        final time = _parseDate(e[timeField]) ?? DateTime(0);
        final existingTime =
            existing == null ? null : _parseDate(existing[timeField]);
        if (existing == null ||
            (existingTime ?? DateTime(0)).isBefore(time)) {
          merged[key] = e;
        }
      }
    }

    if (unchangedKeys != null) {
      merged.forEach((key, value) {
        final local = localByKey[key];
        if (local != null && _sameValue(value, local)) {
          unchangedKeys.add(key);
        }
      });
    }
    return merged.values.toList();
  }

  /// 设置合并：按 key 合并，updatedAt 新者胜；排除同步内部键
  static List<Map<String, dynamic>> _mergeSettings(
    dynamic localList,
    dynamic cloudList,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final list in [localList, cloudList]) {
      if (list is! List) continue;
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final key = e['key']?.toString() ?? '';
        if (key.isEmpty || key == lastSyncKey) continue;
        final existing = merged[key];
        final time = _parseDate(e['updatedAt']) ?? DateTime(0);
        final existingTime =
            existing == null ? null : _parseDate(existing['updatedAt']);
        if (existing == null ||
            (existingTime ?? DateTime(0)).isBefore(time)) {
          merged[key] = e;
        }
      }
    }
    return merged.values.toList();
  }

  /// AI/变位缓存合并：内容相同视为不可变数据直接保留（跳过无谓覆盖），
  /// 内容不同（如 AI 重新查询生成新结果）时取 updatedAt 新者胜
  static dynamic _mergeCache(dynamic a, dynamic b) {
    if (a is! Map<String, dynamic>) return b;
    if (b is! Map<String, dynamic>) return a;
    final aJson = a['json']?.toString() ?? a['conjugationJson']?.toString();
    final bJson = b['json']?.toString() ?? b['conjugationJson']?.toString();
    if (aJson == bJson) return a;
    final aTime = _parseDate(a['updatedAt']) ?? DateTime(0);
    final bTime = _parseDate(b['updatedAt']) ?? DateTime(0);
    return bTime.isAfter(aTime) ? b : a;
  }

  static Map<String, Map<String, dynamic>> _indexDecks(dynamic decks) {
    final map = <String, Map<String, dynamic>>{};
    if (decks is! List) return map;
    for (final d in decks) {
      if (d is! Map<String, dynamic>) continue;
      final name = d['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      // 词书名不区分大小写：与 applyToDatabase / 墓碑匹配规则一致，
      // 避免同一词书两端仅大小写不同时被并成两本词书
      map[name.toLowerCase()] = d;
    }
    return map;
  }

  static Map<String, Map<String, dynamic>> _indexWords(dynamic words) {
    final map = <String, Map<String, dynamic>>{};
    if (words is! List) return map;
    for (final w in words) {
      if (w is! Map<String, dynamic>) continue;
      final german = w['german']?.toString().trim() ?? '';
      if (german.isEmpty) continue;
      map[german.toLowerCase()] = w;
    }
    return map;
  }

  /// 应用词级墓碑过滤：删除后对端无活动的词被剔除（墓碑保留传播），
  /// 对端仍活动/重建的词保留并作废墓碑；返回过滤后的单词列表
  static List<Map<String, dynamic>> _filterTombstonedWords(
    String deckName,
    dynamic words,
    Map<String, Map<String, dynamic>> tombstones,
  ) {
    if (words is! List) return [];
    final result = <Map<String, dynamic>>[];
    for (final w in words) {
      if (w is! Map<String, dynamic>) continue;
      final german = w['german']?.toString().trim() ?? '';
      if (german.isEmpty) {
        result.add(w);
        continue;
      }
      final key = '${deckName.toLowerCase()}|${german.toLowerCase()}';
      final tomb = tombstones[key];
      if (tomb != null) {
        final deletedAt = _parseDate(tomb['deletedAt']);
        if (deletedAt == null) {
          // 墓碑时间戳缺失（异常数据）：不剔除也不作废
          result.add(w);
          continue;
        }
        if (_resurrected(w, deletedAt)) {
          tombstones.remove(key); // 对端仍活动/重建 → 作废墓碑
        } else {
          continue; // 删除后无活动 → 剔除该词，墓碑保留传播
        }
      }
      result.add(w);
    }
    return result;
  }

  /// 索引墓碑列表，键为 (词书名小写|德语原词小写)，词书级墓碑 german 为空串
  static Map<String, Map<String, dynamic>> _indexTombstones(dynamic deletions) {
    final map = <String, Map<String, dynamic>>{};
    if (deletions is! List) return map;
    for (final d in deletions) {
      if (d is! Map<String, dynamic>) continue;
      final deck = d['deck']?.toString().trim() ?? '';
      if (deck.isEmpty) continue;
      final german = d['german']?.toString().trim() ?? '';
      final key = '${deck.toLowerCase()}|${german.toLowerCase()}';
      final existing = map[key];
      // 同键多条（如删了又重建再删）：保留删除时间较晚的一条
      if (existing == null ||
          (_parseDate(d['deletedAt']) ?? DateTime(0))
                  .isAfter(_parseDate(existing['deletedAt']) ?? DateTime(0))) {
        map[key] = d;
      }
    }
    return map;
  }

  /// 合并两端墓碑：并集，同键取删除时间较晚者
  static Map<String, Map<String, dynamic>> _mergeTombstones(
    Map<String, Map<String, dynamic>> local,
    Map<String, Map<String, dynamic>> cloud,
  ) {
    final merged = <String, Map<String, dynamic>>{...cloud};
    local.forEach((key, value) {
      final existing = merged[key];
      if (existing == null) {
        merged[key] = value;
        return;
      }
      final lT = _parseDate(value['deletedAt']);
      final cT = _parseDate(existing['deletedAt']);
      if (lT != null && (cT == null || lT.isAfter(cT))) {
        merged[key] = value;
      }
    });
    return merged;
  }

  /// 该词是否"复活"（删除后对端仍在活动）：
  /// - 创建时间不早于删除时间 → 删除后重建的同名词
  /// - 最后活动（内容编辑/复习）不早于删除时间 → 删除后仍在学习
  static bool _resurrected(Map<String, dynamic> w, DateTime deletedAt) {
    final createdAt = _parseDate(w['createdAt']);
    if (createdAt != null && !createdAt.isBefore(deletedAt)) {
      return true;
    }
    return !_lastActivity(w).isBefore(deletedAt);
  }

  /// 单词最后活动时间 = max(word.updatedAt, sm2.updatedAt)
  /// （复习只更新 sm2，手动调熟练度更新 word；收藏不参与）
  static DateTime _lastActivity(Map<String, dynamic> w) {
    final wordT = _parseDate(w['updatedAt']) ?? DateTime(0);
    final sm2 = w['sm2'];
    if (sm2 is Map<String, dynamic>) {
      final sm2T = _parseDate(sm2['updatedAt']) ?? DateTime(0);
      return wordT.isAfter(sm2T) ? wordT : sm2T;
    }
    return wordT;
  }

  /// 词书最后活动时间 = max(词书 updatedAt, 词书内所有单词的最后活动时间)
  static DateTime _deckLastActivity(Map<String, dynamic> deck) {
    var maxT = _parseDate(deck['updatedAt']) ?? DateTime(0);
    final words = deck['words'];
    if (words is List) {
      for (final w in words) {
        if (w is! Map<String, dynamic>) continue;
        final t = _lastActivity(w);
        if (t.isAfter(maxT)) maxT = t;
      }
    }
    return maxT;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static dynamic _earlierString(dynamic a, dynamic b) {
    final aTime = _parseDate(a);
    final bTime = _parseDate(b);
    if (aTime == null) return b ?? a;
    if (bTime == null) return a;
    return bTime.isBefore(aTime) ? b : a;
  }

  static dynamic _laterString(dynamic a, dynamic b) {
    final aTime = _parseDate(a);
    final bTime = _parseDate(b);
    if (aTime == null) return b ?? a;
    if (bTime == null) return a;
    return bTime.isAfter(aTime) ? b : a;
  }

  /// 可选字符串字段：null/空值转为 Value.absent()，避免误覆盖已有值
  static drift.Value<String?> _optStr(dynamic value) {
    final s = value?.toString();
    if (s == null || s.isEmpty) return const drift.Value.absent();
    return drift.Value(s);
  }

  /// 写入单个单词（含 SM-2、每日统计、变位缓存）
  ///
  /// [canonicalIndex] 是调用方按词书一次性构建的「规范化词形 → 单词」索引：
  /// 命中即在原记录上更新，未命中则新建并把新词补进索引。这样把原先“每个
  /// 单词都全表扫描一次”的 O(n²) 降为 O(n)。
  static Future<void> _applyWord(
    AppDatabase db,
    int deckId,
    Map<String, dynamic> w,
    Map<String, Word> canonicalIndex,
  ) async {
    final german = w['german']?.toString().trim() ?? '';
    if (german.isEmpty) return;
    final now = DateTime.now();
    final createdAt = _parseDate(w['createdAt']) ?? now;
    final updatedAt = _parseDate(w['updatedAt']) ?? now;

    // 词书内规范化匹配：`der Hund` 与 `Hund` 视为同一词，避免同步写入重复
    final key = GermanParser.canonicalKey(german);
    final existing = key.isEmpty ? null : canonicalIndex[key];
    int wordId;
    final companion = WordsCompanion(
      article: _optStr(w['article']),
      baseForm: _optStr(w['baseForm']),
      wordType: _optStr(w['wordType']),
      chinese: drift.Value(w['chinese']?.toString().trim() ?? ''),
      example: _optStr(w['example']),
      tags: _optStr(w['tags']),
      proficiency: drift.Value(_parseInt(w['proficiency']).clamp(0, 5)),
      isFavorite: drift.Value(w['isFavorite'] == true),
      lastStudyDate: drift.Value(_parseDate(w['lastStudyDate'])),
      verbPresent: _optStr(w['verbPresent']),
      verbPast: _optStr(w['verbPast']),
      verbPerfect: _optStr(w['verbPerfect']),
      nounGenitive: _optStr(w['nounGenitive']),
      nounPlural: _optStr(w['nounPlural']),
      nounType: _optStr(w['nounType']),
      adjComparative: _optStr(w['adjComparative']),
      adjSuperlative: _optStr(w['adjSuperlative']),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
    );

    if (existing != null) {
      wordId = existing.id;
      await db.wordDao.updateWord(
        companion.copyWith(
          id: drift.Value(wordId),
          deckId: drift.Value(deckId),
          german: drift.Value(existing.german),
        ),
      );
    } else {
      wordId = await db.wordDao.createWord(
        companion.copyWith(
          deckId: drift.Value(deckId),
          german: drift.Value(german),
        ),
      );
      // 新词补进索引，供同批次后续单词查重命中，避免重复入库
      final created = await db.wordDao.getWordById(wordId);
      if (created != null && key.isNotEmpty) canonicalIndex[key] = created;
    }

    // SM-2 复习状态（upsert，按 wordId 定位更新）
    final sm2 = w['sm2'];
    if (sm2 is Map<String, dynamic>) {
      final sm2Companion = Sm2StatesCompanion(
        wordId: drift.Value(wordId),
        repetitionN: drift.Value(_parseInt(sm2['repetitionN'])),
        intervalDays: drift.Value(_parseDouble(sm2['intervalDays']) ?? 0),
        easeFactor: drift.Value(_parseDouble(sm2['easeFactor']) ?? 2.5),
        nextReview: drift.Value(_parseDate(sm2['nextReview']) ?? now),
        lastReview: drift.Value(_parseDate(sm2['lastReview'])),
        totalReviews: drift.Value(_parseInt(sm2['totalReviews'])),
        correctStreak: drift.Value(_parseInt(sm2['correctStreak'])),
        createdAt: drift.Value(_parseDate(sm2['createdAt']) ?? now),
        updatedAt: drift.Value(_parseDate(sm2['updatedAt']) ?? now),
      );
      final state = await db.sm2Dao.getStateByWordId(wordId);
      if (state != null) {
        await (db.update(db.sm2States)
              ..where((t) => t.wordId.equals(wordId)))
            .write(sm2Companion);
      } else {
        await db.sm2Dao.createState(sm2Companion);
      }
    }

    // 每日错误统计：整组重建（避免残留合并前的旧记录）
    await (db.delete(db.studyStats)..where((t) => t.wordId.equals(wordId)))
        .go();
    final stats = w['stats'];
    if (stats is List) {
      for (final entry in stats) {
        if (entry is! Map<String, dynamic>) continue;
        final date = _parseDate(entry['date']);
        if (date == null) continue;
        try {
          await db.into(db.studyStats).insert(
            StudyStatsCompanion.insert(
              wordId: wordId,
              date: date,
              appearances: drift.Value(_parseInt(entry['appearances'])),
              errors: drift.Value(_parseInt(entry['errors'])),
            ),
          );
        } catch (_) {
          // 单条统计写入失败不影响单词
        }
      }
    }

    // 变位缓存（upsert）
    final conj = w['conjugation'];
    if (conj is Map<String, dynamic>) {
      final json =
          conj['json']?.toString() ?? conj['conjugationJson']?.toString();
      if (json != null && json.isNotEmpty) {
        final conjUpdated = _parseDate(conj['updatedAt']) ?? now;
        await db.into(db.conjugationCache).insert(
          ConjugationCacheCompanion.insert(
            wordId: wordId,
            conjugationJson: json,
            source: drift.Value(conj['source']?.toString() ?? 'ai'),
            createdAt: _parseDate(conj['createdAt']) ?? now,
            updatedAt: conjUpdated,
          ),
          onConflict: drift.DoUpdate(
            (old) => ConjugationCacheCompanion(
              conjugationJson: drift.Value(json),
              source: drift.Value(conj['source']?.toString() ?? 'ai'),
              updatedAt: drift.Value(conjUpdated),
            ),
            target: [db.conjugationCache.wordId],
          ),
        );
      }
    }
  }
}

/// 备份 JSON 的便捷解析/序列化工具
class BackupCodec {
  BackupCodec._();

  /// 当前应用支持的备份格式版本（与导出写入的 'version' 字段一致）
  /// v5：新增 deletions（删除墓碑，跨端删除传播）
  static const int currentVersion = 5;

  static Map<String, dynamic> decode(Uint8List bytes) {
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  static Uint8List encode(Map<String, dynamic> backup) {
    return Uint8List.fromList(utf8.encode(jsonEncode(backup)));
  }
}
