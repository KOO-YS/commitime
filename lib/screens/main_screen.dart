import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'goal_creation_screen.dart';
import 'settings_screen.dart';

/// 메인 화면 - 바텀 네비게이션 포함
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppTab _currentTab = AppTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentTab: _currentTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case AppTab.home:
        return const HomeScreen();
      case AppTab.calendar:
        return const CalendarScreen();
      case AppTab.add:
        // add 탭은 실제로 여기서 렌더링되지 않음
        return const HomeScreen();
      case AppTab.settings:
        return const SettingsScreen();
    }
  }

  void _onTabSelected(AppTab tab) {
    if (tab == AppTab.add) {
      // 목표 생성 화면은 모달로 표시
      _showGoalCreationScreen();
    } else {
      setState(() => _currentTab = tab);
    }
  }

  void _showGoalCreationScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const GoalCreationScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(0, 1), end: Offset.zero);
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return SlideTransition(
            position: tween.animate(curvedAnimation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
