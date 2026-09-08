import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_inbox_service.dart';
import '../../../../core/theme/app_theme.dart';
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
    final profile = _user?['runner_profile'];
    final verificationStatus = profile?['verification_status'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.runnerBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
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
                        Text(_user?['full_name'] ?? 'Runner', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        Text(_user?['phone'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _badge('${(profile?['trust_score'] ?? 70).toStringAsFixed(0)}/100', AppColors.primary, Icons.shield_rounded),
                            const SizedBox(width: 8),
                            _badge('${(profile?['average_rating'] ?? 0.0).toStringAsFixed(1)} ★', AppColors.warning, Icons.star_rounded),
                            const SizedBox(width: 8),
                            _badge(verificationStatus == 'approved' ? 'Verified' : 'Pending', verificationStatus == 'approved' ? AppColors.success : AppColors.warning, Icons.verified_rounded),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _section('Account', [
                    _item(Icons.person_outline_rounded, 'Edit Profile', () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen(isRunner: true)),
                      );
                      if (updated == true) _load();
                    }),
                    _item(Icons.shield_outlined, 'Identity Verification', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerKycScreen()));
                    }),
                    _item(Icons.account_balance_outlined, 'Bank Account', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerBankAccountScreen()));
                    }),
                    _item(Icons.lock_outline_rounded, 'Security & Privacy', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPrivacyScreen(isRunner: true)));
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _section('Preferences', [
                    _item(Icons.notifications_outlined, 'Notifications', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    }),
                    _item(Icons.tune_outlined, 'Notification settings', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()));
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _section('Support', [
                    _item(Icons.help_outline_rounded, 'Help & Support', () {
                      UrlHelper.open(context, AppConstants.supportUrl);
                    }),
                    _item(Icons.logout_rounded, 'Sign Out', _logout, color: AppColors.danger),
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

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.runnerTextMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.runnerSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.runnerBorder)),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70, size: 22),
      title: Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded, color: (color ?? Colors.white).withOpacity(0.3), size: 20),
      onTap: onTap,
    );
  }
}
