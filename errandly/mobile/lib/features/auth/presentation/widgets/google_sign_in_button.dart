import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../../main.dart';
import '../../../customer/presentation/screens/customer_main_screen.dart';
import '../../../runner/presentation/screens/runner_main_screen.dart';
import '../screens/verify_phone_screen.dart';

const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="22px" height="22px">
  <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
  <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
  <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
  <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>
</svg>
''';

class GoogleSignInButton extends StatefulWidget {
  final String role; // 'customer' or 'runner'
  final String label;

  const GoogleSignInButton({
    super.key,
    this.role = 'customer',
    this.label = 'Continue with Google',
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final googleResult = await FirebaseAuthService.instance.signInWithGoogle();
      if (googleResult == null) {
        // User dismissed / canceled sign-in
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final api = getIt<ApiClient>();
      Map<String, String> deviceFields = {};
      try {
        deviceFields = await PushNotificationService.deviceTokenFields();
      } catch (_) {}

      final response = await api.googleLogin({
        'id_token': googleResult.idToken,
        'role': widget.role,
        'email': googleResult.email,
        'first_name': googleResult.displayName,
        ...deviceFields,
      });

      final data = response.data;
      await AuthService.saveToken(data['token']);
      await AuthService.saveUser(Map<String, dynamic>.from(data['user']));
      await AuthService.saveRoles(List<String>.from(data['roles'] ?? [widget.role]));
      try {
        await PushNotificationService.registerDeviceTokenIfPossible();
      } catch (_) {}

      final bool requiresPhone = data['requires_phone_verification'] == true ||
          data['user']?['phone_verified_at'] == null ||
          data['user']?['phone'] == null ||
          (data['user']?['phone'] as String?)?.isEmpty == true;

      if (!mounted) return;

      if (requiresPhone) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPhoneScreen(
              phone: data['user']?['phone'] ?? '',
            ),
          ),
          (_) => false,
        );
      } else {
        if (widget.role == 'runner') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RunnerMainScreen()),
            (_) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
            (_) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorHelper.message(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR CONTINUE WITH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              side: BorderSide(
                color: isDark ? const Color(0xFF2E313D) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.string(_googleSvg, width: 22, height: 22),
                      const SizedBox(width: 12),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
