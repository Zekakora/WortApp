import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/services/import_export/import_service.dart';

void main() {
  group('导入查重兜底', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // 词书A（id=1）
      await db.deckDao.createDeck(DecksCompanion.insert(
        name: '词书A',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      // 词书B（id=2）
      await db.deckDao.createDeck(DecksCompanion.insert(
        name: '词书B',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      // 词书A 中已有 gehen
      await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'gehen',
        article: const drift.Value(''),
        baseForm: const drift.Value('gehen'),
        wordType: const drift.Value('verb'),
        chinese: '去，走',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
    });

    tearDown(() async {
      await db.close();
    });

    /// 写临时 CSV 文件，返回文件路径（测试结束自动清理）
    ///
    /// 注意：csv 包解析器默认行分隔符为 \r\n（Windows 风格），
    /// 直接写入 \n 会导致整份内容被解析为单行。
    Future<String> writeTempCsv(String content) async {
      final dir = await Directory.systemTemp.createTemp('wortapp_import_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/import.csv');
      await file.writeAsString(
        content.replaceAll('\n', '\r\n'),
        encoding: utf8,
      );
      return file.path;
    }

    /// 查询某词书中指定单词的数量
    Future<int> wordCountInDeck(int deckId, String german) async {
      final rows = await (db.select(db.words)
            ..where((t) => t.deckId.equals(deckId) & t.german.equals(german)))
          .get();
      return rows.length;
    }

    test('完整模式导入：与词书内已有单词重复时跳过并计数', () async {
      final path = await writeTempCsv(
          '德语单词,中文,例句\ngehen,走,ich gehe\nlaufen,跑,\ngehen,再走,\n');

      final result = await ImportService(db).importFromFile(
        filePath: path,
        fileName: 'import.csv',
        deckId: 1,
        hasHeader: true,
      );

      expect(result.totalRows, 3);
      expect(result.successCount, 1, reason: '只有 laufen 应成功导入');
      expect(result.skipCount, 2, reason: '两行 gehen 均应被跳过');
      expect(result.errors, anyElement(contains('已存在')));

      // 词书A 中不产生重复记录
      expect(await wordCountInDeck(1, 'gehen'), 1);
      expect(await wordCountInDeck(1, 'laufen'), 1);
    });

    test('完整模式导入：跨词书已存在的单词被全局跳过', () async {
      final path = await writeTempCsv('德语单词,中文\ngehen,走\n');

      final result = await ImportService(db).importFromFile(
        filePath: path,
        fileName: 'import.csv',
        deckId: 2, // 词书B；词书A 中已有 gehen
        hasHeader: true,
      );

      expect(result.successCount, 0, reason: '全局去重：已在词书A 中的 gehen 不再导入词书B');
      expect(result.skipCount, 1);
      expect(await wordCountInDeck(2, 'gehen'), 0);
      expect(await wordCountInDeck(1, 'gehen'), 1);
    });

    test('完整模式导入：带冠词变体与词书内已有单词去重（der Hund vs Hund）', () async {
      await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'Hund',
        chinese: '狗',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      final path = await writeTempCsv('德语单词,中文\nder Hund,狗\nlaufen,跑\n');

      final result = await ImportService(db).importFromFile(
        filePath: path,
        fileName: 'import.csv',
        deckId: 1,
        hasHeader: true,
      );

      expect(result.successCount, 1, reason: '只有 laufen 应成功导入');
      expect(result.skipCount, 1, reason: 'der Hund 与已有 Hund 归为同一词被跳过');
      expect(await wordCountInDeck(1, 'Hund'), 1);
      expect(await wordCountInDeck(1, 'laufen'), 1);
    });

    test('智能模式导入：与词书内已有单词重复时跳过并计数', () async {
      final path = await writeTempCsv('德语单词\ngehen\nlaufen\ngehen\n');

      final result = await ImportService(db).importSimpleMode(
        filePath: path,
        fileName: 'import.csv',
        deckId: 1,
        wordColumnIndex: 0,
        hasHeader: true,
      );

      expect(result.totalRows, 3);
      expect(result.successCount, 1);
      expect(result.skipCount, 2);
      expect(await wordCountInDeck(1, 'gehen'), 1);
      expect(await wordCountInDeck(1, 'laufen'), 1);
    });

    test('备份导入：同词书内重复单词跳过，跨词书重复保留', () async {
      final backup = {
        'type': 'wortapp-backup',
        'app': 'WortApp',
        'version': 2,
        'decks': [
          {
            'name': '词书C',
            'words': [
              {'german': 'der Hund', 'chinese': '狗'},
              {'german': 'der Hund', 'chinese': '狗2'},
              {'german': 'laufen', 'chinese': '跑'},
            ],
          },
          {
            'name': '词书D',
            'words': [
              {'german': 'der Hund', 'chinese': '狗'},
            ],
          },
        ],
        'aiCache': <Object>[],
        'settings': <Object>[],
      };
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

      final result = await ImportService(db).importBackup(
        fileBytes: bytes,
        fileName: 'backup.json',
      );

      expect(result.deckCount, 2);
      expect(result.wordCount, 3,
          reason: '词书C 2 个（der Hund 去重后 + laufen），词书D 1 个');
      expect(result.skipCount, 1, reason: '词书C 中第二个 der Hund 应被跳过');

      final decks = await db.deckDao.getAllDecks();
      final deckC = decks.firstWhere((d) => d.name == '词书C');
      final deckD = decks.firstWhere((d) => d.name == '词书D');
      expect(await wordCountInDeck(deckC.id, 'der Hund'), 1);
      expect(await wordCountInDeck(deckD.id, 'der Hund'), 1);
    });

    test('备份导入：同词书内冠词变体归为同一词去重（der Hund vs Hund）', () async {
      final backup = {
        'type': 'wortapp-backup',
        'app': 'WortApp',
        'version': 2,
        'decks': [
          {
            'name': '词书E',
            'words': [
              {'german': 'Hund', 'chinese': '狗'},
              {'german': 'der Hund', 'chinese': '狗'},
            ],
          },
        ],
        'aiCache': <Object>[],
        'settings': <Object>[],
      };
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

      final result = await ImportService(db).importBackup(
        fileBytes: bytes,
        fileName: 'backup.json',
      );

      expect(result.wordCount, 1,
          reason: 'der Hund 与 Hund 规范化后归为同一词，只保留一个');
      expect(result.skipCount, 1);
    });

    test('备份导入：大小写不同的词不视为重复（Lernen vs lernen）', () async {
      final backup = {
        'type': 'wortapp-backup',
        'app': 'WortApp',
        'version': 2,
        'decks': [
          {
            'name': '词书F',
            'words': [
              {'german': 'lernen', 'chinese': '学习'},
              {'german': 'Lernen', 'chinese': '学习(名词)'},
            ],
          },
        ],
        'aiCache': <Object>[],
        'settings': <Object>[],
      };
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

      final result = await ImportService(db).importBackup(
        fileBytes: bytes,
        fileName: 'backup.json',
      );

      expect(result.wordCount, 2,
          reason: '德语首字母大小写有语义：lernen(动词) 与 Lernen(名词) 是两个词');
      expect(result.skipCount, 0);
    });
  });
}
