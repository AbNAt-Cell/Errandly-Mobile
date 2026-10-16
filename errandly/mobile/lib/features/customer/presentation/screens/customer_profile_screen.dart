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
import '../../../shared/presentation/screens/security_privacy_screen.dart';
import '../../../shared/presentation/screens/edit_profile_screen.dart';
import 'customer_wallet_screen.dart';

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
    final fullName = _user?['full_name'] ?? 'Errandly Customer';
    final email = _user?['email'] ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // User Identity Card (Stitch Gen Z Design)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
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
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 3),
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              child: const Center(
                                child: Icon(Icons.person_rounded, color: AppColors.primary, size: 44),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          fullName,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        _KycBadge(status: _user?['kyc_status'] ?? 'pending', colorScheme: colorScheme),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu Sections
                  _MenuSection(
                    title: 'ACCOUNT & SECURITY',
                    colorScheme: colorScheme,
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile Information',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen(isRunner: false)),
                        ).then((_) => _load()),
                        colorScheme: colorScheme,
                      ),
                      _MenuItem(
                        icon: Icons.verified_user_outlined,
                        label: 'Identity Verification (KYC)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomerKycScreen()),
                        ),
                        colorScheme: colorScheme,
                      ),
                      _MenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Wallet & Payment Methods',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomerWalletScreen()),
                        ),
                        colorScheme: colorScheme,
                      ),
                      _MenuItem(
                        icon: Icons.security_rounded,
                        label: 'Security & Privacy',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SecurityPrivacyScreen(isRunner: false)),
                        ),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _MenuSection(
                    title: 'PREFERENCES & AI',
                    colorScheme: colorScheme,
                    items: [
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
                      _MenuItem(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Errandly AI Assistant',
                        iconColor: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomerAssistantScreen()),
                        ),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _MenuSection(
                    title: 'SESSION',
                    colorScheme: colorScheme,
                    items: [
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Log Out of Account',
                        iconColor: AppColors.danger,
                        textColor: AppColors.danger,
                        onTap: _logout,
                        colorScheme: colorScheme,
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

class _KycBadge extends StatelessWidget {
  final String status;
  final ColorScheme colorScheme;

  const _KycBadge({required this.status, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'approved' => ('ID Verified', AppColors.success, Icons.verified_rounded),
      'submitted' => ('Under Review', AppColors.warning, Icons.hourglass_empty_rounded),
      'rejected' => ('Verification Failed', AppColors.danger, Icons.cancel_rounded),
      _ => ('Pending Verification', AppColors.primary, Icons.shield_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  final ColorScheme colorScheme;

  const _MenuSection({
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
