import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../main.dart';
import '../../../auth/presentation/screens/role_select_screen.dart';
import 'delete_account_screen.dart';

class SecurityPrivacyScreen extends StatefulWidget {
  final bool isRunner;

  const SecurityPrivacyScreen({super.key, this.isRunner = false});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _changingPassword = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _changingPassword = true);
    try {
      final api = getIt<ApiClient>();
      await api.changePassword({
        'current_password': _currentPasswordCtrl.text,
        'password': _newPasswordCtrl.text,
        'password_confirmation': _confirmPasswordCtrl.text,
      });
      await AuthService.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed. Please sign in again.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorHelper.message(e)), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isRunner ? AppColors.runnerBackground : AppColors.background;
    final surface = widget.isRunner ? AppColors.runnerSurface : AppColors.surface;
    final textColor = widget.isRunner ? Colors.white : AppColors.textPrimary;
    final muted = widget.isRunner ? AppColors.runnerTextMuted : AppColors.textSecondary;

    return Theme(
      data: widget.isRunner ? AppTheme.runnerTheme : AppTheme.customerTheme,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: const Text('Security & Privacy'),
          backgroundColor: widget.isRunner ? AppColors.navy : AppColors.surface,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Legal', muted),
            _tile(surface, textColor, Icons.privacy_tip_outlined, 'Privacy Policy',
                () => UrlHelper.open(context, AppConstants.privacyPolicyUrl)),
            _tile(surface, textColor, Icons.description_outlined, 'Terms of Service',
                () => UrlHelper.open(context, AppConstants.termsOfServiceUrl)),
            const SizedBox(height: 20),
            _sectionTitle('Support', muted),
            _tile(surface, textColor, Icons.help_outline_rounded, 'Help & Support',
                () => UrlHelper.open(context, AppConstants.supportUrl)),
            _tile(surface, textColor, Icons.email_outlined, 'Email Support',
                () => UrlHelper.openEmail(context, AppConstants.supportEmail, subject: 'Errandly Support')),
            const SizedBox(height: 20),
            _sectionTitle('Change password', muted),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.isRunner ? AppColors.runnerBorder : AppColors.border),
              ),
              child: Column(
                children: [
                  _passwordField(_currentPasswordCtrl, 'Current password', textColor),
                  const SizedBox(height: 12),
                  _passwordField(_newPasswordCtrl, 'New password', textColor),
                  const SizedBox(height: 12),
                  _passwordField(_confirmPasswordCtrl, 'Confirm new password', textColor),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changingPassword ? null : _changePassword,
                      child: _changingPassword
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Account', muted),
            _tile(surface, AppColors.danger, Icons.delete_forever_outlined, 'Delete Account',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeleteAccountScreen(isRunner: widget.isRunner))),
                danger: true),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _tile(Color surface, Color textColor, IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger ? AppColors.danger.withOpacity(0.3) : (widget.isRunner ? AppColors.runnerBorder : AppColors.border)),
      ),
      child: ListTile(
        leading: Icon(icon, color: danger ? AppColors.danger : (widget.isRunner ? Colors.white70 : AppColors.textSecondary)),
        title: Text(label, style: TextStyle(color: danger ? AppColors.danger : textColor, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded, color: (danger ? AppColors.danger : textColor).withOpacity(0.4)),
        onTap: onTap,
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label, Color textColor) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(labelText: label),
    );
  }
}
