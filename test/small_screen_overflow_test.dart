import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/core/i18n/app_localizations.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/database_provider.dart';
import 'package:wortapp/providers/study_provider.dart';
import 'package:wortapp/ui/screens/study/study_screen.dart';
import 'package:wortapp/ui/screens/study/widgets/spell_mode_screen.dart';

/// 窄屏回归：背词相关页面在 360x800 下不应该出现 RenderFlex overflow
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.deckDao.createDeck(
      DecksCompanion.insert(
        name: '我的德语词书',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await db.wordDao.createWord(
      WordsCompanion.insert(
        deckId: 1,
        german: 'der Rechtschreibfehler',
        chinese: '拼写错误',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(360, 800),
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db), ...overrides],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('背词页 360 宽：参数默认收起，不溢出', (tester) async {
    await pumpScreen(tester, const StudyScreen());
    expect(tester.takeException(), isNull);
  });

  testWidgets('背词页 360 宽：展开练习参数后不溢出', (tester) async {
    await pumpScreen(tester, const StudyScreen());
    final toggle = find.byIcon(Icons.expand_more);
    if (toggle.evaluate().isNotEmpty) {
      await tester.tap(toggle.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('背词页平板宽度：左右分栏不溢出', (tester) async {
    await pumpScreen(tester, const StudyScreen(), size: const Size(1000, 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('拼写模式（打字页）360 宽：不溢出', (tester) async {
    final notifier = StudySessionNotifier(db);
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 50,
      roundLimit: 10,
    );
    await pumpScreen(
      tester,
      const SpellModeScreen(),
      overrides: [studySessionProvider.overrideWith((ref) => notifier)],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('拼写模式：键盘弹出（底部 320 被占）后不出现 bottom overflow', (
    tester,
  ) async {
    final notifier = StudySessionNotifier(db);
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 50,
      roundLimit: 10,
    );
    await pumpScreen(
      tester,
      const SpellModeScreen(),
      overrides: [studySessionProvider.overrideWith((ref) => notifier)],
    );

    // 模拟软键盘弹出：视口底部被遮挡 320px
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
  });
}
