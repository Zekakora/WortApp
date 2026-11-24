import 'package:flutter/material.dart';
import '../../core/i18n/app_localizations.dart';
import '../screens/home/home_screen.dart';
import '../screens/deck/deck_list_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/training/training_home_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  /// 五个一级入口（顺序固定）：主页 / 训练 / 词书 / 查词 / 设置
  ///
  /// 用 IndexedStack 保活各页面状态：切到别的 tab 再回来，
  /// 训练页已生成的练习不会丢。
  final List<Widget> _screens = const [
    HomeScreen(),
    TrainingHomeScreen(),
    DeckListScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.tr('主页'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: context.tr('训练'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_books_outlined),
            selectedIcon: const Icon(Icons.library_books),
            label: context.tr('词书'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: context.tr('查词'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.tr('设置'),
          ),
        ],
      ),
    );
  }
}
