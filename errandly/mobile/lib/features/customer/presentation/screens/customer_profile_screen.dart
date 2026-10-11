import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_inbox_service.dart';
import '../../../../main.dart';
import '../../../auth/presentation/screens/role_select_screen.dart';
import 'customer_assistant_screen.dart';
import 'customer_kyc_screen.dart';
import '../../../shared/presentation/screens/notifications_screen.dart';
import '../../../shared/presentation/screens/notification_preferences_screen.dart';
import '../../../shared/presentation/screens/security_privacy_screen.dart';
import '../../../shared/presentation/screens/edit_profile_screen.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 280,
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: colorScheme.surface.withOpacity(0.2), shape: BoxShape.circle),
                                child: CircleAvatar(backgroundColor: colorScheme.surface, radius: 44, child: Icon(Icons.person, color: colorScheme.primary, size: 48)),
                              ),
                              const SizedBox(height: 16),
                              Text(_user?['full_name'] ?? 'Customer', style: TextStyle(color: colorScheme.onPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text(_user?['email'] ?? '', style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              _KycBadge(status: _user?['kyc_status'] ?? 'pending', colorScheme: colorScheme),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _MenuSection(title: 'Account', colorScheme: colorScheme, items: [
                          _MenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(
                            icon: Icons.shield_outlined,
                            label: 'Identity Verification',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerKycScreen())),
                            colorScheme: colorScheme,
                          ),
                          _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(icon: Icons.payment_outlined, label: 'Payment Methods', onTap: () {}, colorScheme: colorScheme),
                        ]),
                        const SizedBox(height: 24),
                        _MenuSection(title: 'Preferences', colorScheme: colorScheme, items: [
                          _MenuItem(icon: Icons.lock_outline_rounded, label: 'Security & Privacy', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                            colorScheme: colorScheme,
                          ),
                          _MenuItem(
                            icon: Icons.tune_outlined,
                            label: 'Notification settings',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                            ),
                            colorScheme: colorScheme,
                          ),
                          _MenuItem(
                            icon: Icons.smart_toy_outlined,
                            label: 'AI Assistant',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CustomerAssistantScreen()),
                            ),
                            colorScheme: colorScheme,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _MenuSection(title: 'Support', colorScheme: colorScheme, items: [
                          _MenuItem(icon: Icons.logout_rounded, label: 'Sign Out', iconColor: colorScheme.error, textColor: colorScheme.error, onTap: _logout, colorScheme: colorScheme),
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
  final ColorScheme colorScheme;

  const _KycBadge({required this.status, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'approved' => ('Identity Verified', Colors.green.shade300, Icons.verified_rounded),
      'submitted' => ('Under Review', Colors.orange.shade300, Icons.hourglass_empty_rounded),
      'rejected' => ('Verification Failed', Colors.red.shade300, Icons.cancel_rounded),
      _ => ('Verify Identity', colorScheme.onPrimary, Icons.shield_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  final ColorScheme colorScheme;

  const _MenuSection({required this.title, required this.items, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w800)),
        ),
        Container(
          decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outlineVariant)),
          child: Column(
            children: items.map((item) => Column(
              children: [
                item,
                if (item != items.last) Padding(padding: const EdgeInsets.only(left: 56), child: Divider(height: 1, color: colorScheme.outlineVariant)),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final Color? iconColor;
  final Color? textColor;

  const _MenuItem({required this.icon, required this.label, required this.onTap, required this.colorScheme, this.iconColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (iconColor ?? colorScheme.primary).withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 20),
      ),
      title: Text(label, style: TextStyle(color: textColor ?? colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.5), size: 20),
      onTap: onTap,
    );
  }
}
