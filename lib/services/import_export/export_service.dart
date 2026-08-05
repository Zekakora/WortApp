import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../../data/database/app_database.dart';

/// 导出格式
enum ExportFormat {
  csv, // 通用 CSV
  excel, // 通用 Excel
  backupJson, // 数据库备份 JSON（完整数据）
}

/// 导出文件数据（字节 + 文件名，保存/分享由调用方处理，兼容 Web）
class ExportData {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const ExportData({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}

/// 导出结果
class ExportResult {
  final bool success;
  final ExportData? data;
  final String? error;

  const ExportResult({
    required this.success,
    this.data,
    this.error,
  });
}

/// 词书导出服务
///
/// 三种导出方式：
/// - [exportToCsv] / [exportToExcel]：通用格式，便于 Excel/WPS 打开编辑
/// - [exportBackup]：数据库备份 JSON，包含单词全部字段、SM-2 复习状态和变位缓存，用于软件备份恢复
class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

  /// 导出词书为 CSV（带 UTF-8 BOM，保证 Excel 打开中文不乱码）
  Future<ExportResult> exportToCsv({
    required int deckId,
    String? fileName,
  }) async {
    try {
      final deck = await _db.deckDao.getDeckById(deckId);
      if (deck == null) {
        return const ExportResult(success: false, error: '词书不存在');
      }

      final words = await _db.wordDao.getWordsByDeck(deckId);

      // 构建 CSV 数据
      final List<List<dynamic>> csvData = [];

      // 表头
      csvData.add([
        '德语单词',
        '中文释义',
        '例句和拓展',
        '标记',
        '上次学习日期',
        '熟练程度',
        '重复次数',
        '复习间隔(天)',
        '简易度因子',
        '下次复习日期',
      ]);

      // 数据行
      for (final word in words) {
        final sm2State = await _db.sm2Dao.getStateByWordId(word.id);

        csvData.add([
          word.article != null ? '${word.article} ${word.german}' : word.german,
          word.chinese,
          word.example ?? '',
          word.tags ?? '',
          word.lastStudyDate?.toIso8601String() ?? '',
          word.proficiency.toString(),
          sm2State?.repetitionN.toString() ?? '0',
          sm2State?.intervalDays.toString() ?? '0',
          sm2State?.easeFactor.toStringAsFixed(2) ?? '2.50',
          sm2State?.nextReview.toIso8601String() ?? '',
        ]);
      }

      // 前置 BOM，Excel 打开时中文不乱码
      final csvString = '\uFEFF${const ListToCsvConverter().convert(csvData)}';
      final name =
          fileName ?? '${_safeFileName(deck.name)}_${_formatDate(DateTime.now())}.csv';

      return ExportResult(
        success: true,
        data: ExportData(
          bytes: Uint8List.fromList(utf8.encode(csvString)),
          fileName: name,
          mimeType: 'text/csv',
        ),
      );
    } catch (e) {
      return ExportResult(success: false, error: '导出失败: $e');
    }
  }

  /// 导出词书为 Excel
  Future<ExportResult> exportToExcel({
    required int deckId,
    String? fileName,
  }) async {
    try {
      final deck = await _db.deckDao.getDeckById(deckId);
      if (deck == null) {
        return const ExportResult(success: false, error: '词书不存在');
      }

      final words = await _db.wordDao.getWordsByDeck(deckId);

      // 创建 Excel
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // 表头
      sheet.appendRow([
        TextCellValue('德语单词'),
        TextCellValue('中文释义'),
        TextCellValue('例句和拓展'),
        TextCellValue('标记'),
        TextCellValue('上次学习日期'),
        TextCellValue('熟练程度'),
        TextCellValue('重复次数'),
        TextCellValue('复习间隔(天)'),
        TextCellValue('简易度因子'),
        TextCellValue('下次复习日期'),
      ]);

      // 数据行
      for (final word in words) {
        final sm2State = await _db.sm2Dao.getStateByWordId(word.id);

        sheet.appendRow([
          TextCellValue(
              word.article != null ? '${word.article} ${word.german}' : word.german),
          TextCellValue(word.chinese),
          TextCellValue(word.example ?? ''),
          TextCellValue(word.tags ?? ''),
          TextCellValue(word.lastStudyDate?.toIso8601String() ?? ''),
          IntCellValue(word.proficiency),
          IntCellValue(sm2State?.repetitionN ?? 0),
          DoubleCellValue(sm2State?.intervalDays ?? 0),
          DoubleCellValue(sm2State?.easeFactor ?? 2.5),
          TextCellValue(sm2State?.nextReview.toIso8601String() ?? ''),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes == null) {
        return const ExportResult(success: false, error: '生成 Excel 文件失败');
      }

      final name =
          fileName ?? '${_safeFileName(deck.name)}_${_formatDate(DateTime.now())}.xlsx';

      return ExportResult(
        success: true,
        data: ExportData(
          bytes: Uint8List.fromList(fileBytes),
          fileName: name,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );
    } catch (e) {
      return ExportResult(success: false, error: '导出失败: $e');
    }
  }

  /// 导出词书为数据库备份 JSON
  ///
  /// 包含单词全部字段、SM-2 复习状态和变位缓存，用于软件备份与恢复。
  /// [deckIds] 为空时导出全部词书。
  Future<ExportResult> exportBackup({
    List<int>? deckIds,
    String? fileName,
  }) async {
    try {
      final List<Deck> decks;
      if (deckIds == null || deckIds.isEmpty) {
        decks = await _db.deckDao.getAllDecks();
      } else {
        decks = [];
        for (final id in deckIds) {
          final deck = await _db.deckDao.getDeckById(id);
          if (deck != null) decks.add(deck);
        }
      }

      final decksJson = <Map<String, dynamic>>[];
      var wordCount = 0;

      // AI 查词缓存（全表导出，保证恢复后详情页直接命中缓存，不再重复调用 AI）
      final aiCacheRows = await _db.select(_db.aiLookupCache).get();
      final aiCacheJson = aiCacheRows.map((c) => {
            'word': c.word,
            'resultJson': c.resultJson,
            'engine': c.engine,
            'createdAt': c.createdAt.toIso8601String(),
            'updatedAt': c.updatedAt.toIso8601String(),
          }).toList();

      // AI 请求状态记录（全表导出，数据管理页面据此显示请求成功/失败并可一键重试）
      final aiStatusRows = await _db.select(_db.aiRequestStatus).get();
      final aiStatusJson = aiStatusRows.map((s) => {
            'word': s.word,
            'engine': s.engine,
            'status': s.status,
            'errorMessage': s.errorMessage,
            'lastRequestAt': s.lastRequestAt.toIso8601String(),
          }).toList();

      // 每日错误统计（全表导出，按单词分组后挂到对应单词下，恢复时以新 wordId 重建）
      final statsRows = await _db.select(_db.studyStats).get();
      final statsByWord = <int, List<Map<String, dynamic>>>{};
      for (final s in statsRows) {
        statsByWord.putIfAbsent(s.wordId, () => []).add({
          'date': s.date.toIso8601String(),
          'appearances': s.appearances,
          'errors': s.errors,
        });
      }

      // 应用设置（全表导出，恢复后 AI 配置、TTS 语速等设置不丢失）
      final settingsRows = await _db.select(_db.settings).get();
      final settingsJson = settingsRows.map((s) => {
            'key': s.key,
            'value': s.value,
            'updatedAt': s.updatedAt.toIso8601String(),
          }).toList();

      for (final deck in decks) {
        final words = await _db.wordDao.getWordsByDeck(deck.id);
        final cacheMap = await _db.conjugationDao.getCachedByDeck(deck.id);

        final wordsJson = <Map<String, dynamic>>[];
        for (final word in words) {
          final sm2State = await _db.sm2Dao.getStateByWordId(word.id);
          final cache = cacheMap[word.id];

          wordsJson.add({
            'german': word.german,
            'article': word.article,
            'baseForm': word.baseForm,
            'wordType': word.wordType,
            'chinese': word.chinese,
            'example': word.example,
            'tags': word.tags,
            'proficiency': word.proficiency,
            'lastStudyDate': word.lastStudyDate?.toIso8601String(),
            'verbPresent': word.verbPresent,
            'verbPast': word.verbPast,
            'verbPerfect': word.verbPerfect,
            'nounGenitive': word.nounGenitive,
            'nounPlural': word.nounPlural,
            'nounType': word.nounType,
            'adjComparative': word.adjComparative,
            'adjSuperlative': word.adjSuperlative,
            'isFavorite': word.isFavorite,
            'stats': statsByWord[word.id] ?? const [],
            'createdAt': word.createdAt.toIso8601String(),
            'updatedAt': word.updatedAt.toIso8601String(),
            'sm2': sm2State == null
                ? null
                : {
                    'repetitionN': sm2State.repetitionN,
                    'intervalDays': sm2State.intervalDays,
                    'easeFactor': sm2State.easeFactor,
                    'nextReview': sm2State.nextReview.toIso8601String(),
                    'lastReview': sm2State.lastReview?.toIso8601String(),
                    'totalReviews': sm2State.totalReviews,
                    'correctStreak': sm2State.correctStreak,
                    'createdAt': sm2State.createdAt.toIso8601String(),
                    'updatedAt': sm2State.updatedAt.toIso8601String(),
                  },
            'conjugation': cache == null
                ? null
                : {
                    'json': cache.conjugationJson,
                    'source': cache.source,
                    'createdAt': cache.createdAt.toIso8601String(),
                    'updatedAt': cache.updatedAt.toIso8601String(),
                  },
          });
        }

        decksJson.add({
          'name': deck.name,
          'description': deck.description,
          'isActive': deck.isActive,
          'createdAt': deck.createdAt.toIso8601String(),
          'updatedAt': deck.updatedAt.toIso8601String(),
          'words': wordsJson,
        });
        wordCount += words.length;
      }

      final backup = <String, dynamic>{
        'app': 'WortApp',
        'type': 'wortapp-backup',
        'version': 4,
        'exportedAt': DateTime.now().toIso8601String(),
        'deckCount': decksJson.length,
        'wordCount': wordCount,
        'aiCacheCount': aiCacheJson.length,
        'aiStatusCount': aiStatusJson.length,
        'settingsCount': settingsJson.length,
        'decks': decksJson,
        'aiCache': aiCacheJson,
        'aiStatus': aiStatusJson,
        'settings': settingsJson,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      final name = fileName ?? 'WortApp备份_${_formatDate(DateTime.now())}.json';

      return ExportResult(
        success: true,
        data: ExportData(
          bytes: Uint8List.fromList(utf8.encode(jsonString)),
          fileName: name,
          mimeType: 'application/json',
        ),
      );
    } catch (e) {
      return ExportResult(success: false, error: '导出失败: $e');
    }
  }

  /// 过滤文件名中的非法字符
  String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
