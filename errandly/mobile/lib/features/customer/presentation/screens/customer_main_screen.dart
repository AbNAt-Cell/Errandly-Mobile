import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'customer_home_screen.dart';
import 'customer_errands_screen.dart';
import 'customer_wallet_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const CustomerErrandsScreen(),
    const CustomerWalletScreen(),
    const CustomerMessagesScreen(),
    const CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', index: 0, current: _currentIndex, onTap: _setIndex),
                _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Errands', index: 1, current: _currentIndex, onTap: _setIndex),
                _PostButton(onTap: () => Navigator.pushNamed(context, '/customer/errands/new')),
                _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages', index: 3, current: _currentIndex, onTap: _setIndex),
                _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', index: 4, current: _currentIndex, onTap: _setIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setIndex(int i) => setState(() => _currentIndex = i);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primary : AppColors.textMuted, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppColors.primary : AppColors.textMuted, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PostButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
