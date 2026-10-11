import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_inbox_service.dart';
import '../../../../main.dart';
import '../../../auth/presentation/screens/role_select_screen.dart';
import 'runner_kyc_screen.dart';
import 'runner_bank_account_screen.dart';
import '../../../shared/presentation/screens/notifications_screen.dart';
import '../../../shared/presentation/screens/notification_preferences_screen.dart';
import '../../../shared/presentation/screens/security_privacy_screen.dart';
import '../../../shared/presentation/screens/edit_profile_screen.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/url_helper.dart';

class RunnerProfileScreen extends StatefulWidget {
  const RunnerProfileScreen({super.key});

  @override
  State<RunnerProfileScreen> createState() => _RunnerProfileScreenState();
}

class _RunnerProfileScreenState extends State<RunnerProfileScreen> {
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
      setState(() { _user = res.data['user']; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    NotificationInboxService.clear();
    await AuthService.clearAll();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RoleSelectScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final profile = _user?['runner_profile'];
    final verificationStatus = profile?['verification_status'] ?? 'pending';

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
                              Text(_user?['full_name'] ?? 'Runner', style: TextStyle(color: colorScheme.onPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text(_user?['phone'] ?? '', style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _Badge(label: '${(profile?['trust_score'] ?? 70).toStringAsFixed(0)}/100', color: colorScheme.onPrimary, icon: Icons.shield_rounded, backgroundColor: colorScheme.onPrimary.withOpacity(0.2)),
                                  const SizedBox(width: 8),
                                  _Badge(label: '${(profile?['average_rating'] ?? 0.0).toStringAsFixed(1)} ★', color: Colors.orange.shade300, icon: Icons.star_rounded, backgroundColor: Colors.orange.shade300.withOpacity(0.2)),
                                  const SizedBox(width: 8),
                                  _Badge(
                                    label: verificationStatus == 'approved' ? 'Verified' : 'Pending', 
                                    color: verificationStatus == 'approved' ? Colors.green.shade300 : Colors.orange.shade300, 
                                    icon: verificationStatus == 'approved' ? Icons.verified_rounded : Icons.hourglass_empty_rounded, 
                                    backgroundColor: (verificationStatus == 'approved' ? Colors.green.shade300 : Colors.orange.shade300).withOpacity(0.2)
                                  ),
                                ],
                              ),
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
                        _Section(title: 'Account', colorScheme: colorScheme, items: [
                          _MenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(icon: Icons.shield_outlined, label: 'Identity Verification', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerKycScreen())), colorScheme: colorScheme),
                          _MenuItem(icon: Icons.account_balance_outlined, label: 'Bank Account', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerBankAccountScreen())), colorScheme: colorScheme),
                        ]),
                        const SizedBox(height: 24),
                        _Section(title: 'Performance', colorScheme: colorScheme, items: [
                          _MenuItem(icon: Icons.star_border_rounded, label: 'My Ratings', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(icon: Icons.task_alt_rounded, label: 'Completion Stats', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(icon: Icons.trending_up_rounded, label: 'Trust Score', onTap: () {}, colorScheme: colorScheme),
                        ]),
                        const SizedBox(height: 24),
                        _Section(title: 'Preferences', colorScheme: colorScheme, items: [
                          _MenuItem(icon: Icons.schedule_rounded, label: 'Availability Schedule', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(icon: Icons.map_outlined, label: 'Service Areas', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())), colorScheme: colorScheme),
                          _MenuItem(icon: Icons.tune_outlined, label: 'Notification settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())), colorScheme: colorScheme),
                        ]),
                        const SizedBox(height: 24),
                        _Section(title: 'Support', colorScheme: colorScheme, items: [
                          _MenuItem(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}, colorScheme: colorScheme),
                          _MenuItem(icon: Icons.logout_rounded, label: 'Sign Out', onTap: _logout, colorScheme: colorScheme, iconColor: colorScheme.error, textColor: colorScheme.error),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final Color backgroundColor;

  const _Badge({required this.label, required this.color, required this.icon, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(20)),
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

class _Section extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  final ColorScheme colorScheme;

  const _Section({required this.title, required this.items, required this.colorScheme});

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
            children: items.map((item) {
              return Column(
                children: [
                  item,
                  if (item != items.last) Padding(padding: const EdgeInsets.only(left: 56), child: Divider(height: 1, color: colorScheme.outlineVariant)),
                ],
              );
            }).toList(),
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
