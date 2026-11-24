import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wortapp/app.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WortApp(),
      ),
    );

    // 本地化代理（GlobalMaterialLocalizations 等）异步加载，需再 pump 一帧后界面才渲染
    await tester.pump();

    // Verify that the app renders
    expect(find.text('WortApp'), findsOneWidget);

    // 等待数据库初始化完成/超时定时器过期，避免测试结束时仍有 pending Timer
    await tester.pump(const Duration(seconds: 11));
  });
}
