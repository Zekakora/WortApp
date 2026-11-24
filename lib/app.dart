import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'ui/navigation/app_navigation.dart';

class WortApp extends ConsumerWidget {
  const WortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // 同步全局语言状态，供非 Widget 环境（算法 / Provider / Service）读取
    final locale = Locale(settings.languageCode);
    AppLocale.code = settings.languageCode;

    return MaterialApp(
      title: 'WortApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _resolveThemeMode(settings.themeMode),
      // 界面语言：中文 / 英语 / 德语
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppNavigation(),
    );
  }

  /// 将设置中的主题模式字符串转换为 [ThemeMode]
  ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
