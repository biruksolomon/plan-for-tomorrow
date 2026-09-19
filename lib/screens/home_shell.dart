import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';
import 'new_streak_screen.dart';
import 'plan_tomorrow_screen.dart';
import 'settings_screen.dart';
import 'streaks_list_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    TodayScreen(),
    StreaksListScreen(),
    HistoryScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_index]),
      floatingActionButton: _fab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.paper2,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline, color: AppColors.muted),
            selectedIcon: Icon(Icons.check_circle, color: AppColors.accent),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.local_fire_department, color: AppColors.accent),
            label: 'Streaks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.accent),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.insights, color: AppColors.accent),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.settings, color: AppColors.accent),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget? _fab(BuildContext context) {
    if (_index == 0) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        elevation: 0,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlanTomorrowScreen()),
        ),
        icon: const Icon(Icons.edit_outlined, size: 19),
        label: Text(
          context.watch<AppState>().needsTomorrowPlan ? 'Plan tomorrow' : 'Edit tomorrow',
          style: AppTheme.body(14, color: AppColors.paper, weight: FontWeight.w600),
        ),
      );
    }
    if (_index == 1) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        elevation: 0,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewStreakScreen()),
        ),
        icon: const Icon(Icons.add, size: 19),
        label: Text(
          'New streak',
          style: AppTheme.body(14, color: AppColors.paper, weight: FontWeight.w600),
        ),
      );
    }
    return null;
  }
}