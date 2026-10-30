import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import 'customer_home_screen.dart';
import 'customer_errands_screen.dart';
import 'customer_wallet_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'create_errand_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;
  int _unreadMessagesCount = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.syncUserChannel();
    _fetchUnread();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchUnread());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnread() async {
    try {
      final res = await getIt<ApiClient>().getConversations();
      final data = res.data;
      final list = data is List ? data : (data is Map ? (data['data'] ?? []) : []);
      int unread = 0;
      if (list is List) {
        for (final c in list) {
          if (c is Map && c['unread_count'] != null) {
            unread += (c['unread_count'] as num).toInt();
          }
        }
      }
      if (mounted) {
        setState(() => _unreadMessagesCount = unread);
      }
    } catch (_) {}
  }

  late final List<Widget> _screens = [
    CustomerHomeScreen(
      onOpenProfile: () => setState(() => _currentIndex = 4),
    ),
    const CustomerErrandsScreen(),
    const CustomerWalletScreen(),
    const CustomerMessagesScreen(),
    const CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _FloatingAddBubble(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateErrandScreen()),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  current: _currentIndex,
                  onTap: _setIndex,
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Errands',
                  index: 1,
                  current: _currentIndex,
                  onTap: _setIndex,
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  index: 2,
                  current: _currentIndex,
                  onTap: _setIndex,
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  index: 3,
                  current: _currentIndex,
                  onTap: _setIndex,
                  badgeCount: _unreadMessagesCount,
                ),
                _NavItem(
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
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.primary : colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: colorScheme.surface, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? AppColors.primary : colorScheme.onSurfaceVariant,
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

class _FloatingAddBubble extends StatefulWidget {
  final VoidCallback onTap;
  const _FloatingAddBubble({required this.onTap});

  @override
  State<_FloatingAddBubble> createState() => _FloatingAddBubbleState();
}

class _FloatingAddBubbleState extends State<_FloatingAddBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.90,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _animController;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Post an Errand',
      child: GestureDetector(
        onTapDown: (_) => _animController.reverse(),
        onTapUp: (_) {
          _animController.forward();
          widget.onTap();
        },
        onTapCancel: () => _animController.forward(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF8A3D),
                  AppColors.primary,
                  Color(0xFFE55A00),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(-1, -2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glossy bubble highlight
                Positioned(
                  top: 5,
                  child: Container(
                    width: 28,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
