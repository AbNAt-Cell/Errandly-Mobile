import 'package:flutter/material.dart';
import '../../../../core/services/realtime_service.dart';
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

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.syncUserChannel();
  }

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
            color: AppColors.surfaceDark,
            border: const Border(top: BorderSide(color: AppColors.borderDark)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  _RunnerNavItem(
                    icon: Icons.task_alt_outlined,
                    activeIcon: Icons.task_alt_rounded,
                    label: 'Tasks',
                    index: 0,
                    current: _currentIndex,
                    onTap: _setIndex,
                  ),
                  _RunnerNavItem(
                    icon: Icons.payments_outlined,
                    activeIcon: Icons.payments_rounded,
                    label: 'Earnings',
                    index: 1,
                    current: _currentIndex,
                    onTap: _setIndex,
                  ),
                  _RunnerNavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Messages',
                    index: 2,
                    current: _currentIndex,
                    onTap: _setIndex,
                  ),
                  _RunnerNavItem(
                    icon: Icons.history_rounded,
                    activeIcon: Icons.history_rounded,
                    label: 'Activity',
                    index: 3,
                    current: _currentIndex,
                    onTap: _setIndex,
                  ),
                  _RunnerNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                    current: _currentIndex,
                    onTap: _setIndex,
                  ),
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
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _RunnerNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : AppColors.textSecondaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? AppColors.primary : AppColors.textSecondaryDark,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
