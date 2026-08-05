import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import '../../core/utils/german_parser.dart';
import '../../data/database/app_database.dart';

/// 导入结果
class ImportResult {
  final int totalRows;
  final int successCount;
  final int skipCount;
  final List<String> errors;

  const ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.skipCount,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isFullySuccessful => successCount == totalRows;
}

/// 文件预览数据
class FilePreview {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final String fileName;

  const FilePreview({
    required this.headers,
    required this.rows,
    required this.fileName,
  });
}

/// 导入模式
enum ImportMode {
  simple,     // 简单模式：只导入单词，AI自动获取词意
  full,       // 完整模式：导入所有列（德语、中文、例句等）
}

/// 数据库备份导入结果
class BackupImportResult {
  final int deckCount; // 成功导入的词书数
  final int wordCount; // 成功导入的单词数
  final int skipCount; // 跳过的单词数（重复）
  final List<String> errors;

  const BackupImportResult({
    required this.deckCount,
    required this.wordCount,
    required this.skipCount,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

/// Excel/CSV 导入服务
class ImportService {
  final AppDatabase _db;

  ImportService(this._db);

  /// 预览文件内容（支持文件路径或字节数据）
  Future<FilePreview> previewFile({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    int maxRows = 10,
  }) async {
    final ext = fileName.toLowerCase().split('.').last;

    if (ext == 'csv') {
      return _previewCsv(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        maxRows: maxRows,
      );
    } else if (ext == 'xlsx' || ext == 'xls') {
      return _previewExcel(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        maxRows: maxRows,
      );
    } else {
      throw Exception('不支持的文件格式: .$ext');
    }
  }

  /// 预览CSV文件
  Future<FilePreview> _previewCsv({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    int maxRows = 10,
  }) async {
    String content;

    if (kIsWeb && fileBytes != null) {
      // Web平台使用字节数据
      content = utf8.decode(fileBytes);
    } else if (filePath != null) {
      // 原生平台使用文件路径
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      content = await file.readAsString();
    } else {
      throw Exception('未提供文件数据');
    }

    // 去除 UTF-8 BOM（本应用导出的 CSV 带 BOM，避免 Excel 乱码）
    content = content.replaceFirst(RegExp(r'^\uFEFF'), '');

    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) {
      return FilePreview(headers: [], rows: [], fileName: fileName);
    }

    final headers = rows.first.map((e) => e?.toString() ?? '').toList();
    final dataRows = rows.skip(1).take(maxRows).toList();

    return FilePreview(
      headers: headers,
      rows: dataRows,
      fileName: fileName,
    );
  }

  /// 预览Excel文件
  Future<FilePreview> _previewExcel({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    int maxRows = 10,
  }) async {
    Uint8List bytes;

    if (kIsWeb && fileBytes != null) {
      // Web平台使用字节数据
      bytes = fileBytes;
    } else if (filePath != null) {
      // 原生平台使用文件路径
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      bytes = await file.readAsBytes();
    } else {
      throw Exception('未提供文件数据');
    }

    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      return FilePreview(headers: [], rows: [], fileName: fileName);
    }

    final sheet = excel.tables.values.first;
    final allRows = sheet.rows
        .map((row) => row.map((cell) => cell?.value).toList())
        .toList();

    if (allRows.isEmpty) {
      return FilePreview(headers: [], rows: [], fileName: fileName);
    }

    final headers = allRows.first.map((e) => e?.toString() ?? '').toList();
    final dataRows = allRows.skip(1).take(maxRows).toList();

    return FilePreview(
      headers: headers,
      rows: dataRows,
      fileName: fileName,
    );
  }

  /// 从文件导入词书（支持文件路径或字节数据）
  Future<ImportResult> importFromFile({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required int deckId,
    bool hasHeader = true,
  }) async {
    final ext = fileName.toLowerCase().split('.').last;

    if (ext == 'csv') {
      return importFromCsv(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        deckId: deckId,
        hasHeader: hasHeader,
      );
    } else if (ext == 'xlsx' || ext == 'xls') {
      return importFromExcel(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        deckId: deckId,
        hasHeader: hasHeader,
      );
    } else {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        skipCount: 0,
        errors: ['不支持的文件格式: .$ext'],
      );
    }
  }

  /// 简单模式导入：只导入单词列，AI后续自动获取词意（支持文件路径或字节数据）
  Future<ImportResult> importSimpleMode({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required int deckId,
    required int wordColumnIndex,
    bool hasHeader = true,
  }) async {
    final ext = fileName.toLowerCase().split('.').last;
    List<List<dynamic>> rows;

    if (ext == 'csv') {
      String content;
      if (kIsWeb && fileBytes != null) {
        content = utf8.decode(fileBytes);
      } else if (filePath != null) {
        final file = File(filePath);
        if (!await file.exists()) {
          return ImportResult(
            totalRows: 0,
            successCount: 0,
            skipCount: 0,
            errors: ['文件不存在: $filePath'],
          );
        }
        content = await file.readAsString();
      } else {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          skipCount: 0,
          errors: ['未提供文件数据'],
        );
      }
      // 去除 UTF-8 BOM（本应用导出的 CSV 带 BOM，避免 Excel 乱码）
      content = content.replaceFirst(RegExp(r'^\uFEFF'), '');
      rows = const CsvToListConverter().convert(content);
    } else if (ext == 'xlsx' || ext == 'xls') {
      Uint8List bytes;
      if (kIsWeb && fileBytes != null) {
        bytes = fileBytes;
      } else if (filePath != null) {
        final file = File(filePath);
        if (!await file.exists()) {
          return ImportResult(
            totalRows: 0,
            successCount: 0,
            skipCount: 0,
            errors: ['文件不存在: $filePath'],
          );
        }
        bytes = await file.readAsBytes();
      } else {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          skipCount: 0,
          errors: ['未提供文件数据'],
        );
      }
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          skipCount: 0,
          errors: ['Excel 文件没有工作表'],
        );
      }

      final sheet = excel.tables.values.first;
      rows = sheet.rows
          .map((row) => row.map((cell) => cell?.value).toList())
          .toList();
    } else {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        skipCount: 0,
        errors: ['不支持的文件格式: .$ext'],
      );
    }

    return _processRowsSimpleMode(
      rows: rows,
      deckId: deckId,
      wordColumnIndex: wordColumnIndex,
      hasHeader: hasHeader,
    );
  }

  /// 处理简单模式导入（只导入单词列）
  Future<ImportResult> _processRowsSimpleMode({
    required List<List<dynamic>> rows,
    required int deckId,
    required int wordColumnIndex,
    bool hasHeader = true,
  }) async {
    final errors = <String>[];
    int successCount = 0;
    int skipCount = 0;

    // 跳过表头
    final dataRows = hasHeader ? rows.skip(1).toList() : rows;
    final totalRows = dataRows.length;

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final rowNum = i + (hasHeader ? 2 : 1);

      try {
        if (wordColumnIndex >= row.length) {
          errors.add('行 $rowNum: 列索引超出范围');
          skipCount++;
          continue;
        }

        final german = _cleanString(row[wordColumnIndex]?.toString() ?? '');

        if (german.isEmpty) {
          errors.add('行 $rowNum: 单词为空');
          skipCount++;
          continue;
        }

        // 先解析德语单词
        final parsed = GermanParser.parse(german);

        // 检查是否已存在（使用解析后的主干）
        final existing = await _db.wordDao.findWordByGerman(deckId, parsed.baseWord);
        if (existing != null) {
          skipCount++;
          continue;
        }

        // 创建单词记录（中文暂时为空，后续AI填充）
        final now = DateTime.now();
        await _db.wordDao.createWord(
          WordsCompanion(
            deckId: drift.Value(deckId),
            german: drift.Value(parsed.baseWord),
            article: drift.Value(parsed.article),
            baseForm: drift.Value(parsed.baseWord),
            wordType: drift.Value(parsed.wordType.name),
            chinese: const drift.Value(''),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        successCount++;
      } catch (e) {
        errors.add('行 $rowNum: 导入失败 - $e');
        skipCount++;
      }
    }

    return ImportResult(
      totalRows: totalRows,
      successCount: successCount,
      skipCount: skipCount,
      errors: errors,
    );
  }

  /// 从 CSV 导入（支持文件路径或字节数据）
  Future<ImportResult> importFromCsv({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required int deckId,
    bool hasHeader = true,
  }) async {
    String content;

    if (kIsWeb && fileBytes != null) {
      content = utf8.decode(fileBytes);
    } else if (filePath != null) {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          skipCount: 0,
          errors: ['文件不存在: $filePath'],
        );
      }
      content = await file.readAsString();
    } else {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        skipCount: 0,
        errors: ['未提供文件数据'],
      );
    }

    // 去除 UTF-8 BOM（本应用导出的 CSV 带 BOM，避免 Excel 乱码）
    content = content.replaceFirst(RegExp(r'^\uFEFF'), '');

    final rows = const CsvToListConverter().convert(content);

    return _processRows(rows: rows, deckId: deckId, hasHeader: hasHeader);
  }

  /// 从 Excel 导入（支持文件路径或字节数据）
  Future<ImportResult> importFromExcel({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required int deckId,
    bool hasHeader = true,
  }) async {
    Uint8List bytes;

    if (kIsWeb && fileBytes != null) {
      bytes = fileBytes;
    } else if (filePath != null) {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          skipCount: 0,
          errors: ['文件不存在: $filePath'],
        );
      }
      bytes = await file.readAsBytes();
    } else {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        skipCount: 0,
        errors: ['未提供文件数据'],
      );
    }

    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        skipCount: 0,
        errors: ['Excel 文件没有工作表'],
      );
    }

    // 使用第一个工作表
    final sheet = excel.tables.values.first;
    final rows = sheet.rows
        .map((row) => row.map((cell) => cell?.value).toList())
        .toList();

    return _processRows(rows: rows, deckId: deckId, hasHeader: hasHeader);
  }

  /// 从数据库备份文件导入（WortApp 备份 JSON，支持文件路径或字节数据）
  ///
  /// 备份包含完整的词书结构：词书信息、单词全部字段、SM-2 复习状态、变位缓存。
  /// 同名词书会自动追加序号；同一单词允许在不同词书中同时存在（共享 AI 查词缓存）。
  /// [wipeExisting] 为 true 时先清空所有数据（词书、单词、学习记录、AI 缓存、设置），
  /// 再完整覆盖为备份内容，用于“完全覆盖恢复”。
  Future<BackupImportResult> importBackup({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    bool wipeExisting = false,
  }) async {
    String content;

    // 字节优先（Web 与测试环境），原生平台也可用文件路径
    if (fileBytes != null) {
      content = utf8.decode(fileBytes);
    } else if (filePath != null) {
      final file = File(filePath);
      if (!await file.exists()) {
        return const BackupImportResult(
          deckCount: 0,
          wordCount: 0,
          skipCount: 0,
          errors: ['文件不存在'],
        );
      }
      content = await file.readAsString();
    } else {
      return const BackupImportResult(
        deckCount: 0,
        wordCount: 0,
        skipCount: 0,
        errors: ['未提供文件数据'],
      );
    }

    // 去除 UTF-8 BOM
    content = content.replaceFirst(RegExp(r'^\uFEFF'), '');

    Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return BackupImportResult(
        deckCount: 0,
        wordCount: 0,
        skipCount: 0,
        errors: ['备份文件解析失败: $e'],
      );
    }

    if (data['type'] != 'wortapp-backup') {
      return const BackupImportResult(
        deckCount: 0,
        wordCount: 0,
        skipCount: 0,
        errors: ['不是有效的 WortApp 备份文件'],
      );
    }

    final decks = data['decks'];
    if (decks is! List) {
      return const BackupImportResult(
        deckCount: 0,
        wordCount: 0,
        skipCount: 0,
        errors: ['备份文件中缺少词书数据'],
      );
    }

    // 完全覆盖模式：备份文件已验证有效，先清空所有数据再导入
    // （子表先删避免外键约束；清空后库为空，后续导入自然完整还原）
    if (wipeExisting) {
      try {
        await _db.transaction(() async {
          await _db.delete(_db.aiLookupCache).go();
          await _db.delete(_db.conjugationCache).go();
          await _db.delete(_db.sm2States).go();
          await _db.delete(_db.words).go();
          await _db.delete(_db.decks).go();
          await _db.delete(_db.settings).go();
        });
      } catch (e) {
        return BackupImportResult(
          deckCount: 0,
          wordCount: 0,
          skipCount: 0,
          errors: ['清空现有数据失败: $e'],
        );
      }
    }

    final errors = <String>[];
    var deckCount = 0;
    var wordCount = 0;
    var skipCount = 0;
    // 记录新导入词书中需要恢复激活状态的（词书ID, 是否激活）
    final importedActives = <(int, bool)>[];

    for (final deckJson in decks) {
      if (deckJson is! Map<String, dynamic>) continue;
      try {
        final deckName = deckJson['name']?.toString().trim() ?? '';
        if (deckName.isEmpty) {
          errors.add('跳过：备份中存在无名称的词书');
          continue;
        }

        final deckId = await _createDeckWithUniqueName(
          deckName,
          deckJson['description']?.toString(),
          createdAt: _parseDate(deckJson['createdAt']),
          updatedAt: _parseDate(deckJson['updatedAt']),
        );
        deckCount++;
        importedActives.add((deckId, deckJson['isActive'] == true));

        final wordsJson = deckJson['words'];
        if (wordsJson is List) {
          for (final wordJson in wordsJson) {
            if (wordJson is! Map<String, dynamic>) continue;
            final result = await _importBackupWord(deckId, wordJson);
            wordCount += result.$1;
            skipCount += result.$2;
            if (result.$3 != null) errors.add(result.$3!);
          }
        }
      } catch (e) {
        errors.add('词书导入失败: $e');
      }
    }

    // 恢复 AI 查词缓存（v1 旧备份无此字段时跳过）
    final aiCache = data['aiCache'];
    if (aiCache is List) {
      for (final entry in aiCache) {
        if (entry is! Map<String, dynamic>) continue;
        final word = entry['word']?.toString() ?? '';
        final resultJson = entry['resultJson']?.toString() ?? '';
        if (word.isEmpty || resultJson.isEmpty) continue;
        try {
          await _db.aiCacheDao.saveToCache(
            word: word,
            resultJson: resultJson,
            engine: entry['engine']?.toString() ?? 'ai',
          );
        } catch (e) {
          errors.add('AI 缓存恢复失败: $e');
        }
      }
    }

    // 恢复应用设置（v1 旧备份无此字段时跳过）
    final settings = data['settings'];
    if (settings is List) {
      for (final entry in settings) {
        if (entry is! Map<String, dynamic>) continue;
        final key = entry['key']?.toString() ?? '';
        final value = entry['value']?.toString();
        if (key.isEmpty || value == null) continue;
        try {
          await _db.setSetting(key, value);
        } catch (e) {
          errors.add('设置恢复失败: $e');
        }
      }
    }

    // 恢复激活状态：仅当当前没有激活词书，且备份中存在激活词书时
    final activeDeck = await _db.deckDao.getActiveDeck();
    if (activeDeck == null && importedActives.isNotEmpty) {
      for (final entry in importedActives) {
        if (entry.$2) {
          await _db.deckDao.setActiveDeck(entry.$1);
          break;
        }
      }
    }

    return BackupImportResult(
      deckCount: deckCount,
      wordCount: wordCount,
      skipCount: skipCount,
      errors: errors,
    );
  }

  /// 创建词书，名称冲突时自动追加序号（如 “德语A1(1)”）
  Future<int> _createDeckWithUniqueName(
    String name,
    String? description, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final all = await _db.deckDao.getAllDecks();
    final existingNames = all.map((d) => d.name).toSet();

    var finalName = name;
    var suffix = 1;
    while (existingNames.contains(finalName)) {
      finalName = '$name($suffix)';
      suffix++;
    }

    final now = DateTime.now();
    return _db.deckDao.createDeck(
      DecksCompanion(
        name: drift.Value(finalName),
        description: description == null || description.isEmpty
            ? const drift.Value.absent()
            : drift.Value(description),
        createdAt: drift.Value(createdAt ?? now),
        updatedAt: drift.Value(updatedAt ?? now),
      ),
    );
  }

  /// 导入备份中的单个单词（含 SM-2 状态与变位缓存），返回 (成功数, 跳过数, 错误信息)
  ///
  /// 不做全局查重：同一单词允许在不同词书中同时存在（共享 AI 查词缓存）。
  Future<(int, int, String?)> _importBackupWord(
    int deckId,
    Map<String, dynamic> w,
  ) async {
    try {
      final german = _cleanString(w['german']?.toString() ?? '');
      if (german.isEmpty) return (0, 1, null);

      // 词书内查重：同一词书内不允许重复（跨词书允许重复，共享 AI 查词缓存）
      final existing = await _db.wordDao.findWordByGerman(deckId, german);
      if (existing != null) return (0, 1, null);

      final now = DateTime.now();
      final wordId = await _db.wordDao.createWord(
        WordsCompanion(
          deckId: drift.Value(deckId),
          german: drift.Value(german),
          article: _optStr(w['article']),
          baseForm: _optStr(w['baseForm']),
          wordType: _optStr(w['wordType']),
          chinese: drift.Value(_cleanString(w['chinese']?.toString() ?? '')),
          example: _optStr(w['example']),
          tags: _optStr(w['tags']),
          proficiency: drift.Value(_parseInt(w['proficiency']).clamp(0, 5)),
          lastStudyDate: drift.Value(_parseDate(w['lastStudyDate'])),
          verbPresent: _optStr(w['verbPresent']),
          verbPast: _optStr(w['verbPast']),
          verbPerfect: _optStr(w['verbPerfect']),
          nounGenitive: _optStr(w['nounGenitive']),
          nounPlural: _optStr(w['nounPlural']),
          nounType: _optStr(w['nounType']),
          adjComparative: _optStr(w['adjComparative']),
          adjSuperlative: _optStr(w['adjSuperlative']),
          createdAt: drift.Value(_parseDate(w['createdAt']) ?? now),
          updatedAt: drift.Value(_parseDate(w['updatedAt']) ?? now),
        ),
      );

      // 恢复 SM-2 复习状态
      final sm2 = w['sm2'];
      if (sm2 is Map<String, dynamic>) {
        final sm2State = await _db.sm2Dao.getStateByWordId(wordId);
        final companion = Sm2StatesCompanion(
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
        if (sm2State != null) {
          await (_db.update(_db.sm2States)
                ..where((t) => t.wordId.equals(wordId)))
              .write(companion);
        } else {
          await _db.sm2Dao.createState(companion);
        }
      }

      // 恢复变位缓存（含创建/更新时间戳，保证与备份完全一致）
      final conj = w['conjugation'];
      if (conj is Map<String, dynamic>) {
        final json = conj['json']?.toString() ?? conj['conjugationJson']?.toString();
        if (json != null && json.isNotEmpty) {
          final now2 = DateTime.now();
          await _db.into(_db.conjugationCache).insert(
            ConjugationCacheCompanion.insert(
              wordId: wordId,
              conjugationJson: json,
              source: drift.Value(conj['source']?.toString() ?? 'ai'),
              createdAt: _parseDate(conj['createdAt']) ?? now2,
              updatedAt: _parseDate(conj['updatedAt']) ?? now2,
            ),
            onConflict: drift.DoUpdate(
              (old) => ConjugationCacheCompanion(
                conjugationJson: drift.Value(json),
                source: drift.Value(conj['source']?.toString() ?? 'ai'),
                updatedAt: drift.Value(_parseDate(conj['updatedAt']) ?? now2),
              ),
              // 必须显式指定冲突目标为 wordId 唯一键
              target: [_db.conjugationCache.wordId],
            ),
          );
        }
      }

      return (1, 0, null);
    } catch (e) {
      return (0, 0, '单词导入失败: $e');
    }
  }

  /// 处理行数据
  Future<ImportResult> _processRows({
    required List<List<dynamic>> rows,
    required int deckId,
    bool hasHeader = true,
  }) async {
    final errors = <String>[];
    int successCount = 0;
    int skipCount = 0;

    // 跳过表头
    final dataRows = hasHeader ? rows.skip(1).toList() : rows;
    final totalRows = dataRows.length;

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final rowNum = i + (hasHeader ? 2 : 1);

      try {
        if (row.length < 2) {
          errors.add('行 $rowNum: 列数不足，至少需要德语和中文两列');
          skipCount++;
          continue;
        }

        final german = _cleanString(row[0]?.toString() ?? '');
        final chinese = _cleanString(row[1]?.toString() ?? '');

        if (german.isEmpty || chinese.isEmpty) {
          errors.add('行 $rowNum: 德语或中文为空');
          skipCount++;
          continue;
        }

        // 解析德语单词
        final parsed = GermanParser.parse(german);

        // 词书内查重：同一词书内不允许重复，重复单词跳过
        // （跨词书允许重复，共享 AI 查词缓存）
        final existing =
            await _db.wordDao.findWordByGerman(deckId, parsed.baseWord);
        if (existing != null) {
          errors.add('行 $rowNum: 单词“${parsed.baseWord}”已存在，已跳过');
          skipCount++;
          continue;
        }

        // 提取可选字段
        final example = row.length > 2 ? _cleanString(row[2]?.toString() ?? '') : null;
        final tags = row.length > 3 ? _cleanString(row[3]?.toString() ?? '') : null;
        final lastStudyDate = row.length > 4 ? _parseDate(row[4]) : null;
        final proficiency = row.length > 5 ? _parseInt(row[5]) : 0;

        // 创建单词记录
        final now = DateTime.now();
        await _db.wordDao.createWord(
          WordsCompanion(
            deckId: drift.Value(deckId),
            german: drift.Value(parsed.baseWord),
            article: drift.Value(parsed.article),
            baseForm: drift.Value(parsed.baseWord),
            wordType: drift.Value(parsed.wordType.name),
            chinese: drift.Value(chinese),
            example: drift.Value(example?.isEmpty == true ? null : example),
            tags: drift.Value(tags?.isEmpty == true ? null : tags),
            proficiency: drift.Value(proficiency.clamp(0, 5)),
            lastStudyDate: drift.Value(lastStudyDate),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        successCount++;
      } catch (e) {
        errors.add('行 $rowNum: 导入失败 - $e');
        skipCount++;
      }
    }

    return ImportResult(
      totalRows: totalRows,
      successCount: successCount,
      skipCount: skipCount,
      errors: errors,
    );
  }

  /// 清理字符串
  String _cleanString(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 解析日期
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// 解析整数
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 解析浮点数
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 可选字符串字段：null/空值转为 Value.absent()，避免误覆盖数据库已有值
  drift.Value<String?> _optStr(dynamic value) {
    final s = value?.toString();
    if (s == null || s.isEmpty) return const drift.Value.absent();
    return drift.Value(s);
  }
}
