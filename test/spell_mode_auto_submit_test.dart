import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/database_provider.dart';
import 'package:wortapp/providers/study_provider.dart';
import 'package:wortapp/ui/screens/study/widgets/spell_mode_screen.dart';

/// 拼写模式的自动确认（autoConfirm）不该在键盘收起后自动作答
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 1, 1);
    await db.deckDao.createDeck(
      DecksCompanion.insert(name: 'A', createdAt: now, updatedAt: now),
    );
    await db.wordDao.createWord(WordsCompanion.insert(
      deckId: 1,
      german: 'Haus',
      chinese: '房子',
      createdAt: now,
      updatedAt: now,
    ));
    // 自动确认开启（拼写模式＝停止输入 800ms 后自动判定）
    await db.setSetting('autoConfirm', 'true');

    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await container.read(studySessionProvider.notifier).startSession(deckId: 1);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SpellModeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 已判定（出现反馈按钮）为真
  bool answered() => find.text('忘记').evaluate().isNotEmpty;

  testWidgets('键盘收起（输入框失焦）后不再自动提交', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'Haus');
    await tester.pump();

    // 用户收起输入法：输入框失去焦点
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    // 超过防抖时间
    await tester.pump(const Duration(seconds: 2));

    expect(answered(), isFalse,
        reason: '收起输入法不应触发自动判定，否则会把没输完的词判错');
  });

  testWidgets('输入法仍在组词（未上屏）时不自动提交', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'H');
    await tester.pump();
    // 模拟输入法组词中：composing 未提交
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'Haus',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 0, end: 4),
    ));
    await tester.pump(const Duration(seconds: 2));

    expect(answered(), isFalse,
        reason: '组词未上屏时不能判定，否则等于在输入法里「选词」就把题交了');
  });

  testWidgets('输入框保持焦点时，停止输入后仍会自动判定（自动确认功能保留）',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Haus');
    await tester.pump(const Duration(seconds: 2));

    expect(answered(), isTrue, reason: '自动确认在键盘仍打开时应照常工作');
  });

  testWidgets('未聚焦时点击德语特殊字符不崩溃', (tester) async {
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('ä'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ä'));
    await tester.pumpAndSettle();

    // 仍然是拼写页（没有抛 RangeError 把页面打红）
    expect(find.byType(SpellModeScreen), findsOneWidget);
  });
}
