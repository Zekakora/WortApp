import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/database_provider.dart';
import 'package:wortapp/providers/search_provider.dart';
import 'package:wortapp/services/dictionary/dictionary_engine.dart';
import 'package:wortapp/ui/screens/search/search_screen.dart';

/// 预置一条查词结果的 SearchNotifier（避免测试触网）
class _StubSearchNotifier extends SearchNotifier {
  _StubSearchNotifier(super.ref, DictionaryResult result) {
    state = SearchResult(result: result);
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  const result = DictionaryResult(
    word: 'Hund',
    article: 'der',
    definitions: ['狗'],
    examples: ['Der Hund bellt.'],
    partOfSpeech: 'noun',
    engine: 'AI 解析',
  );

  Future<void> pumpSearchScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          searchProvider.overrideWith((ref) => _StubSearchNotifier(ref, result)),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder nameField() => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == '词书名称',
      );

  /// 收尾：让 SnackBar 自动消失并卸载组件树，
  /// 跑掉 drift 关闭查询流时挂的零延迟定时器（否则 flutter_test 报 pending timer，
  /// 且 tearDown 里的 db.close() 会一直等下去导致整个用例超时）
  Future<void> drainTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox.shrink());
    // 注意：pump() 不推进假时钟，必须给出非零时长才会执行零延迟定时器
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('加入词书 → 新建词书：不黑屏，单词写入新词书', (tester) async {
    await pumpSearchScreen(tester);

    // 打开词书选择面板
    await tester.tap(find.text('加入词书'));
    await tester.pumpAndSettle();
    expect(find.text('选择词书'), findsOneWidget);

    // 展开内联「新建词书」表单（面板里还有一个空状态按钮，这里点标题栏那个）
    await tester.tap(find.widgetWithText(TextButton, '新建词书'));
    await tester.pumpAndSettle();
    expect(nameField(), findsOneWidget);

    await tester.enterText(nameField(), '生词本');
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建并添加'));
    await tester.pumpAndSettle();

    // 回归点：页面没有被多余的 Navigator.pop 弹掉（旧实现会只剩黑屏）
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('联网查词'), findsOneWidget);
    // 面板已关闭
    expect(find.text('选择词书'), findsNothing);

    // 新词书已创建，单词已入库
    final decks = await db.deckDao.getAllDecks();
    expect(decks, hasLength(1));
    expect(decks.single.name, '生词本');
    final words = await db.wordDao.getWordsByDeck(decks.single.id);
    expect(words, hasLength(1));
    expect(words.single.german, 'Hund');
    expect(words.single.chinese, '狗');

    // 成功提示
    expect(find.text('已添加到词书'), findsOneWidget);

    await drainTimers(tester);
  });

  testWidgets('词书名称为空时给出内联错误且不创建词书', (tester) async {
    await pumpSearchScreen(tester);

    await tester.tap(find.text('加入词书'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '新建词书'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建并添加'));
    await tester.pumpAndSettle();

    expect(find.text('请填写词书名称'), findsOneWidget);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(await db.deckDao.getAllDecks(), isEmpty);

    await drainTimers(tester);
  });

  testWidgets('直接选择已有词书：面板关闭并入库', (tester) async {
    final now = DateTime(2026, 1, 1);
    await db.deckDao.createDeck(
      DecksCompanion.insert(name: '已有词书', createdAt: now, updatedAt: now),
    );
    await pumpSearchScreen(tester);

    await tester.tap(find.text('加入词书'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('已有词书'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('选择词书'), findsNothing);
    final words = await db.wordDao.getWordsByDeck(1);
    expect(words.single.german, 'Hund');
    expect(find.text('已添加到词书'), findsOneWidget);

    await drainTimers(tester);
  });

  testWidgets('单词已存在于其它词书：提示不重复添加，也不再新建空词书', (tester) async {
    final now = DateTime(2026, 1, 1);
    final deckId = await db.deckDao.createDeck(
      DecksCompanion.insert(name: '旧词书', createdAt: now, updatedAt: now),
    );
    await db.wordDao.createWord(WordsCompanion.insert(
      deckId: deckId,
      german: 'Hund',
      chinese: '狗',
      createdAt: now,
      updatedAt: now,
    ));
    await pumpSearchScreen(tester);

    await tester.tap(find.text('加入词书'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '新建词书'));
    await tester.pumpAndSettle();
    await tester.enterText(nameField(), '生词本');
    await tester.tap(find.text('创建并添加'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(await db.deckDao.getAllDecks(), hasLength(1));
    expect(find.text('该单词已存在于词书「旧词书」，未重复添加'), findsOneWidget);

    await drainTimers(tester);
  });

  testWidgets('输入已存在的词书名：复用它而不是新建同名词书', (tester) async {
    final now = DateTime(2026, 1, 1);
    await db.deckDao.createDeck(
      DecksCompanion.insert(name: '生词本', createdAt: now, updatedAt: now),
    );
    await pumpSearchScreen(tester);

    await tester.tap(find.text('加入词书'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '新建词书'));
    await tester.pumpAndSettle();
    await tester.enterText(nameField(), '生词本');
    await tester.tap(find.text('创建并添加'));
    await tester.pumpAndSettle();

    final decks = await db.deckDao.getAllDecks();
    expect(decks, hasLength(1), reason: '不应产生同名词书');
    expect(await db.wordDao.getWordsByDeck(decks.single.id), hasLength(1));

    await drainTimers(tester);
  });
}
