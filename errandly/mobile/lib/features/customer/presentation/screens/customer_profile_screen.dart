import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_inbox_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../auth/presentation/screens/role_select_screen.dart';
import 'customer_assistant_screen.dart';
import 'customer_kyc_screen.dart';
import '../../../shared/presentation/screens/notifications_screen.dart';
import '../../../shared/presentation/screens/notification_preferences_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.me();
      setState(() {
        _user = res.data['user'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    NotificationInboxService.clear();
    await AuthService.clearAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RoleSelectScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.navy,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.navy,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const CircleAvatar(backgroundColor: AppColors.primary, radius: 40, child: Icon(Icons.person, color: Colors.white, size: 48)),
                        const SizedBox(height: 12),
                        Text(_user?['full_name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        Text(_user?['email'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        const SizedBox(height: 8),
                        _KycBadge(status: _user?['kyc_status'] ?? 'pending'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _MenuSection(items: [
                    _MenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {}),
                    _MenuItem(
                      icon: Icons.shield_outlined,
                      label: 'Identity Verification',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerKycScreen())),
                    ),
                    _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () {}),
                    _MenuItem(icon: Icons.payment_outlined, label: 'Payment Methods', onTap: () {}),
                  ]),
                  const SizedBox(height: 16),
                  _MenuSection(items: [
                    _MenuItem(icon: Icons.lock_outline_rounded, label: 'Security & Privacy', onTap: () {}),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.tune_outlined,
                      label: 'Notification settings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.smart_toy_outlined,
                      label: 'AI Assistant',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerAssistantScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _MenuSection(items: [
                    _MenuItem(icon: Icons.logout_rounded, label: 'Sign Out', color: AppColors.danger, onTap: _logout),
                  ]),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  final String status;
  const _KycBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'approved' => ('Identity Verified', AppColors.success, Icons.verified_rounded),
      'submitted' => ('Under Review', AppColors.warning, Icons.hourglass_empty_rounded),
      'rejected' => ('Verification Failed', AppColors.danger, Icons.cancel_rounded),
      _ => ('Verify Identity', AppColors.textMuted, Icons.shield_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        children: items.map((item) => Column(
          children: [
            ListTile(
              leading: Icon(item.icon, color: item.color ?? AppColors.textSecondary, size: 22),
              title: Text(item.label, style: TextStyle(color: item.color ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right_rounded, color: item.color?.withOpacity(0.5) ?? AppColors.textMuted, size: 20),
              onTap: item.onTap,
            ),
            if (item != items.last) const Divider(height: 1, indent: 52),
          ],
        )).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});
}
