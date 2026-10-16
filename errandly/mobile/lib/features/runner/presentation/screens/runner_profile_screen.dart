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
      if (mounted) {
        setState(() {
          _user = res.data['user'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    NotificationInboxService.clear();
    await AuthService.clearAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = _user?['runner_profile'];
    final verificationStatus = profile?['verification_status'] ?? 'pending';
    final runnerName = _user?['full_name'] ?? 'Runner';
    final phone = _user?['phone'] ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Runner Profile',
          style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface, fontSize: 18),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Runner Identity Card (Stitch Gen Z Design)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 3),
                                color: colorScheme.primary.withValues(alpha: 0.12),
                              ),
                              child: Center(
                                child: Icon(Icons.two_wheeler_rounded, color: colorScheme.primary, size: 40),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                verificationStatus == 'approved' ? Icons.verified_rounded : Icons.pending_rounded,
                                color: verificationStatus == 'approved' ? AppColors.success : AppColors.warning,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          runnerName,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Badge(
                              label: 'Trust: ${(profile?['trust_score'] ?? 70).toStringAsFixed(0)}',
                              color: AppColors.primary,
                              icon: Icons.shield_rounded,
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              label: '${(profile?['average_rating'] ?? 5.0).toStringAsFixed(1)} ★',
                              color: AppColors.warning,
                              icon: Icons.star_rounded,
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              label: verificationStatus == 'approved' ? 'Verified' : 'Pending',
                              color: verificationStatus == 'approved' ? AppColors.success : AppColors.warning,
                              icon: verificationStatus == 'approved' ? Icons.verified_rounded : Icons.hourglass_empty_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sections
                  _Section(
                    title: 'ACCOUNT & VERIFICATION',
                    colorScheme: colorScheme,
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile Information',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen(isRunner: true)),
                        ).then((_) => _load()),
                        colorScheme: colorScheme,
                      ),
                      _MenuItem(
                        icon: Icons.verified_user_outlined,
                        label: 'Identity Verification (KYC)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RunnerKycScreen()),
                        ),
                        colorScheme: colorScheme,
                      ),
                      _MenuItem(
                        icon: Icons.account_balance_outlined,
                        label: 'Linked Payout Bank Account',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RunnerBankAccountScreen()),
                        ),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _Section(
                    title: 'SETTINGS & PREFERENCES',
                    colorScheme: colorScheme,
                    items: [
                      _MenuItem(
                        icon: Icons.security_rounded,
                        label: 'Security & Privacy',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SecurityPrivacyScreen(isRunner: true)),
                        ),
                        colorScheme: colorScheme,
                      ),
                      _MenuItem(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications Inbox',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                        colorScheme: colorScheme,
                      ),
                      _MenuItem(
                        icon: Icons.tune_rounded,
                        label: 'Notification Preferences',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                        ),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _Section(
                    title: 'SUPPORT & LEGAL',
                    colorScheme: colorScheme,
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Runner Help & Support',
                        onTap: () => UrlHelper.openEmail(
                          context,
                          AppConstants.supportEmail,
                          subject: 'Runner Support Request',
                        ),
                        colorScheme: colorScheme,
                      ),
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out of Runner Mode',
                        onTap: _logout,
                        colorScheme: colorScheme,
                        iconColor: AppColors.danger,
                        textColor: AppColors.danger,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  final ColorScheme colorScheme;

  const _Section({
    required this.title,
    required this.items,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (idx < items.length - 1)
                    Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
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

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
