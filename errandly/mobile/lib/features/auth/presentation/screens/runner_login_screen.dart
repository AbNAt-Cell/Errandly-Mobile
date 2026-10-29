import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../../main.dart';
import '../../../runner/presentation/screens/runner_main_screen.dart';
import 'forgot_password_screen.dart';
import 'runner_register_screen.dart';

enum RunnerAuthMode { phone, password }

class RunnerLoginScreen extends StatefulWidget {
  const RunnerLoginScreen({super.key});

  @override
  State<RunnerLoginScreen> createState() => _RunnerLoginScreenState();
}

class _RunnerLoginScreenState extends State<RunnerLoginScreen> {
  RunnerAuthMode _authMode = RunnerAuthMode.phone;

  // Password fields
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  // Phone OTP fields
  final _phoneCtrl = TextEditingController();
  String _otp = '';
  String? _verificationId;
  bool _codeSent = false;
  bool _loading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // Password login
  Future<void> _loginWithPassword() async {
    if (_loginCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your credentials'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final api = getIt<ApiClient>();
      final deviceFields = await PushNotificationService.deviceTokenFields();
      final response = await api.login({
        'login': _loginCtrl.text.trim(),
        'password': _passwordCtrl.text,
        ...deviceFields,
      });

      final data = response.data;
      await AuthService.saveToken(data['token']);
      await AuthService.saveUser(Map<String, dynamic>.from(data['user']));
      await AuthService.saveRoles(List<String>.from(data['roles'] ?? ['runner']));
      await PushNotificationService.registerDeviceTokenIfPossible();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RunnerMainScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorHelper.message(e)), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Firebase Phone OTP: Step 1 Send Code
  Future<void> _sendFirebaseOtp() async {
    final rawPhone = _phoneCtrl.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _loading = true);
    await FirebaseAuthService.instance.sendPhoneVerification(
      phoneNumber: rawPhone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _loading = false;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification SMS sent via Firebase!'), backgroundColor: AppColors.success),
        );
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.danger),
        );
      },
      onAutoVerified: (idToken) {
        if (!mounted) return;
        debugPrint('[RunnerLogin] Firebase phone auto-verified.');
        _completeFirebaseLogin(idToken);
      },
    );
  }

  // Firebase Phone OTP: Step 2 Verify OTP & Login
  Future<void> _verifyOtpAndLogin() async {
    if (_verificationId == null) return;
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final idToken = await FirebaseAuthService.instance.verifySmsCodeAndGetIdToken(
        verificationId: _verificationId!,
        smsCode: _otp,
      );

      if (idToken == null) {
        throw Exception('Could not retrieve Firebase authentication token.');
      }

      await _completeFirebaseLogin(idToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorHelper.message(e)), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeFirebaseLogin(String idToken) async {
    try {
      final api = getIt<ApiClient>();
      final deviceFields = await PushNotificationService.deviceTokenFields();
      final response = await api.firebaseLogin({
        'id_token': idToken,
        'role': 'runner',
        ...deviceFields,
      });

      final data = response.data;
      await AuthService.saveToken(data['token']);
      await AuthService.saveUser(Map<String, dynamic>.from(data['user']));
      await AuthService.saveRoles(List<String>.from(data['roles'] ?? ['runner']));
      await PushNotificationService.registerDeviceTokenIfPossible();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RunnerMainScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorHelper.message(e)), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.runnerTheme,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🏃', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Runner Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Sign in to your runner account', style: TextStyle(fontSize: 14, color: AppColors.runnerTextMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _authMode = RunnerAuthMode.phone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _authMode == RunnerAuthMode.phone ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android_rounded,
                                  size: 18,
                                  color: _authMode == RunnerAuthMode.phone ? Colors.white : AppColors.runnerTextMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Phone OTP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _authMode == RunnerAuthMode.phone ? Colors.white : AppColors.runnerTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _authMode = RunnerAuthMode.password),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _authMode == RunnerAuthMode.password ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: _authMode == RunnerAuthMode.password ? Colors.white : AppColors.runnerTextMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _authMode == RunnerAuthMode.password ? Colors.white : AppColors.runnerTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_authMode == RunnerAuthMode.phone) ...[
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    enabled: !_codeSent,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+2348012345678 or 08012345678',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.phone_outlined, color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: AppColors.navyLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      suffixIcon: _codeSent
                          ? TextButton(
                              onPressed: () => setState(() {
                                _codeSent = false;
                                _otp = '';
                                _verificationId = null;
                              }),
                              child: const Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_codeSent) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendFirebaseOtp,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Send SMS Verification Code'),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Enter 6-digit code sent via SMS:',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      keyboardType: TextInputType.number,
                      textStyle: const TextStyle(color: Colors.white),
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(10),
                        fieldHeight: 52,
                        fieldWidth: 44,
                        activeFillColor: AppColors.navyLight,
                        inactiveFillColor: AppColors.navyLight,
                        selectedFillColor: AppColors.navyLight,
                        activeColor: AppColors.primary,
                        selectedColor: AppColors.primary,
                        inactiveColor: Colors.white.withOpacity(0.2),
                      ),
                      onChanged: (v) {
                        setState(() => _otp = v);
                        if (v.length == 6) {
                          _verifyOtpAndLogin();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_loading || _otp.length != 6) ? null : _verifyOtpAndLogin,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Verify & Sign In'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _resendCountdown > 0 ? null : _sendFirebaseOtp,
                        child: Text(
                          _resendCountdown > 0 ? 'Resend code in ${_resendCountdown}s' : 'Resend SMS code',
                          style: TextStyle(
                            color: _resendCountdown > 0 ? AppColors.runnerTextMuted : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  TextField(
                    controller: _loginCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email or Phone',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: AppColors.navyLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: !_showPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white.withOpacity(0.5)),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      filled: true,
                      fillColor: AppColors.navyLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Forgot password?', style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _loginWithPassword,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Sign In as Runner'),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have a runner account? ", style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RunnerRegisterScreen()),
                      ),
                      child: const Text('Sign up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
