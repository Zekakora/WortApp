import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wortapp/services/dictionary/godic_engine.dart';

void main() {
  group('GedicDictionaryEngine.parseDefinitions', () {
    test('提取释义并剥离序号', () {
      const html = '''
<div id="ExpFCchild" class="expDiv">
<br><span class="cara">Ⅰ m, -(e)s, -e</span><br>
<span class="exp">①狗，犬</span><br>
<span class="eg"><i>Vorsicht, bissiger Hund!</i></span><br>
<span class="exp">②（俗）人，家伙</span><br>
<br><span class="cara">Ⅱ m, -(e)s, -e</span><br>
<span class="exp">③<img class="dictimgtoword" src="https://www.godic.net/tmp/wordimg/a.png">矿车，煤车，运输车</span>
</div>
''';
      final defs = GedicDictionaryEngine.parseDefinitions(html);
      expect(defs, ['狗，犬', '（俗）人，家伙', '矿车，煤车，运输车']);
    });

    test('剥离 <img> 与解释性标签，兼容 img 带闭合标签', () {
      const html = '''
<span class="exp">⑭ <img class="dictimgtoword" src="https://www.godic.net/tmp/wordimg/a.png"></img>向，朝向</span>
<span class="exp"><宾语所指的是一段距离时,则完成时可用sein或haben>跑出;跑完</宾语所指的是一段距离时,则完成时可用sein或haben></span>
''';
      final defs = GedicDictionaryEngine.parseDefinitions(html);
      expect(defs, ['向，朝向', '跑出;跑完']);
    });

    test('兼容序号前带空白的释义', () {
      const html =
          '<span class="exp"> ① 非常,十分,特别</span>';
      final defs = GedicDictionaryEngine.parseDefinitions(html);
      expect(defs, ['非常,十分,特别']);
    });

    test('不匹配例句块（p.exp）与近义词块', () {
      const html = '''
<div class="lj_item"><p class="exp">(<span class="key">口</span>)他们相处得很不和睦。</p></div>
<div id="ExpSYNchild" class="expDiv"><h5>近义词：</h5><a href="/dicts/de/Katze">Katze</a></div>
''';
      final defs = GedicDictionaryEngine.parseDefinitions(html);
      expect(defs, isEmpty);
    });

    test('无释义返回空列表', () {
      expect(GedicDictionaryEngine.parseDefinitions(''), isEmpty);
      expect(GedicDictionaryEngine.parseDefinitions('<html><body>not found</body></html>'), isEmpty);
    });
  });

  group('GedicDictionaryEngine.lookup', () {
    test('解析词条页为纯释义，标记 wordOnly，不携带其他字段', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), contains('/dicts/de/Hund'));
        return http.Response(
          '<html><div class="expDiv">'
          '<span class="exp">①狗，犬</span>'
          '<span class="exp">②（俗）人，家伙</span>'
          '</div><div class="lj_item"><p class="exp">例句释义不被匹配</p></div></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final engine = GedicDictionaryEngine(client: client);
      final result = await engine.lookup('Hund');

      expect(result, isNotNull);
      expect(result!.word, 'Hund');
      expect(result.definitions, ['狗，犬', '（俗）人，家伙']);
      expect(result.examples, isEmpty);
      expect(result.article, isNull);
      expect(result.partOfSpeech, isNull);
      expect(result.inflection, isNull);
      expect(result.engine, '德语助手');
      expect(result.wordOnly, isTrue);
    });

    test('非 200（词条不存在时重定向登录）返回 null', () async {
      final client = MockClient((request) async => http.Response('', 302));
      final engine = GedicDictionaryEngine(client: client);
      expect(await engine.lookup('asdfqw1234'), isNull);
    });

    test('页面无释义返回 null', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><body>请输入正确的单词</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final engine = GedicDictionaryEngine(client: client);
      expect(await engine.lookup('xyz'), isNull);
    });

    test('网络异常时返回 null 而非抛出', () async {
      final client = MockClient((request) async {
        throw http.ClientException('connection failed');
      });
      final engine = GedicDictionaryEngine(client: client);
      expect(await engine.lookup('Hund'), isNull);
    });
  });
}
