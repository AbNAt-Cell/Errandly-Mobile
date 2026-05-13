import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'runner_home_screen.dart';
import 'runner_earnings_screen.dart';
import 'runner_messages_screen.dart';
import 'runner_activity_screen.dart';
import 'runner_profile_screen.dart';

class RunnerMainScreen extends StatefulWidget {
  const RunnerMainScreen({super.key});

  @override
  State<RunnerMainScreen> createState() => _RunnerMainScreenState();
}

class _RunnerMainScreenState extends State<RunnerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const RunnerHomeScreen(),
    const RunnerEarningsScreen(),
    const RunnerMessagesScreen(),
    const RunnerActivityScreen(),
    const RunnerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.runnerTheme,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.runnerBackground,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _RunnerNavItem(icon: Icons.task_alt_rounded, label: 'Tasks', index: 0, current: _currentIndex, onTap: _setIndex),
                  _RunnerNavItem(icon: Icons.account_balance_wallet_rounded, label: 'Earnings', index: 1, current: _currentIndex, onTap: _setIndex),
                  _RunnerNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', index: 2, current: _currentIndex, onTap: _setIndex),
                  _RunnerNavItem(icon: Icons.history_rounded, label: 'Activity', index: 3, current: _currentIndex, onTap: _setIndex),
                  _RunnerNavItem(icon: Icons.person_outline_rounded, label: 'Profile', index: 4, current: _currentIndex, onTap: _setIndex),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setIndex(int i) => setState(() => _currentIndex = i);
}

class _RunnerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _RunnerNavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : AppColors.runnerTextMuted, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppColors.primary : AppColors.runnerTextMuted, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}
