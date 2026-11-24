import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wortapp/services/dictionary/wiktionary_engine.dart';

void main() {
  group('WiktionaryEngine.cleanDefinitions', () {
    test('剔除词源段，仅保留释义句', () {
      const extract = '''
From Middle High German hunt, from Old High German hunt, from Proto-West Germanic *hund, from Proto-Germanic *hundaz, from Proto-Indo-European *ḱwn̥tós, from *ḱwṓ ("dog").

(This etymology is missing or incomplete. Please add to it, or discuss it at the Etymology scriptorium.)

A dog (animal).
An animal of the family Canidae.
(derogatory) A contemptible person; a scoundrel.
''';
      final defs = WiktionaryEngine.cleanDefinitions(extract);
      expect(defs, [
        'A dog (animal).',
        'An animal of the family Canidae.',
        '(derogatory) A contemptible person; a scoundrel.',
      ]);
    });

    test('剔除行内音标/来源中括号与句首编号', () {
      const extract =
          '1. A large body of water.\n2. [figuratively] A large quantity.\n3. [from Old English] A formal writing.';
      final defs = WiktionaryEngine.cleanDefinitions(extract);
      expect(defs, [
        'A large body of water.',
        'A large quantity.',
        'A formal writing.',
      ]);
    });

    test('IPA/音标与 Rhymes 行被剔除', () {
      const extract =
          'IPA(key): /hʊnt/\nRhymes: -ʊnt\nA dog (animal).';
      final defs = WiktionaryEngine.cleanDefinitions(extract);
      expect(defs, ['A dog (animal).']);
    });

    test('空摘要返回空列表', () {
      expect(WiktionaryEngine.cleanDefinitions(''), isEmpty);
      expect(WiktionaryEngine.cleanDefinitions('   \n  '), isEmpty);
    });

    test('仅词源时返回空列表', () {
      const extract =
          'From Middle High German hunt, from Old High German hunt.';
      expect(WiktionaryEngine.cleanDefinitions(extract), isEmpty);
    });

    test('正常词义句保留', () {
      const extract = 'A dog (animal).';
      final defs = WiktionaryEngine.cleanDefinitions(extract);
      expect(defs, ['A dog (animal).']);
    });
  });

  group('WiktionaryEngine.lookup', () {
    test('解析摘要为纯释义，标记 wordOnly，不携带其他字段', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('Hund'));
        return http.Response(
          jsonEncode({
            'title': 'Hund',
            'extract': 'From Middle High German hunt.\n'
                'A dog (animal).\n'
                'An animal of the family Canidae.',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final engine = WiktionaryEngine(client: client);
      final result = await engine.lookup('Hund');

      expect(result, isNotNull);
      expect(result!.word, 'Hund');
      expect(result.definitions, ['A dog (animal).', 'An animal of the family Canidae.']);
      expect(result.examples, isEmpty);
      expect(result.article, isNull);
      expect(result.partOfSpeech, isNull);
      expect(result.inflection, isNull);
      expect(result.engine, 'Wiktionary');
      expect(result.wordOnly, isTrue);
    });

    test('非 200 返回 null', () async {
      final client = MockClient((request) async => http.Response('', 404));
      final engine = WiktionaryEngine(client: client);
      expect(await engine.lookup('Hund'), isNull);
    });

    test('摘要无有效释义时返回 null', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'title': 'Hund',
            'extract': 'From Middle High German hunt, from Old High German hunt.',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final engine = WiktionaryEngine(client: client);
      expect(await engine.lookup('Hund'), isNull);
    });

    test('网络异常时返回 null 而非抛出', () async {
      final client = MockClient((request) async {
        throw http.ClientException('connection failed');
      });
      final engine = WiktionaryEngine(client: client);
      expect(await engine.lookup('Hund'), isNull);
    });
  });
}
