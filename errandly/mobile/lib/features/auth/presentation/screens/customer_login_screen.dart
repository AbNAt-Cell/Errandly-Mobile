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
import '../../../customer/presentation/screens/customer_main_screen.dart';
import 'customer_register_screen.dart';
import 'forgot_password_screen.dart';

enum CustomerAuthMode { phone, password }

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerAuthMode _authMode = CustomerAuthMode.phone;

  // Password login controllers
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  // Phone login controllers & state
  final _phoneController = TextEditingController();
  String _otp = '';
  String? _verificationId;
  bool _codeSent = false;
  bool _loading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
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

  // --- Password Login ---
  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = getIt<ApiClient>();
      final deviceFields = await PushNotificationService.deviceTokenFields();
      final response = await api.login({
        'login': _loginController.text.trim(),
        'password': _passwordController.text,
        ...deviceFields,
      });

      final data = response.data;
      await AuthService.saveToken(data['token']);
      await AuthService.saveUser(Map<String, dynamic>.from(data['user']));
      await AuthService.saveRoles(List<String>.from(data['roles'] ?? ['customer']));
      await PushNotificationService.registerDeviceTokenIfPossible();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
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

  // --- Firebase Phone Login: Step 1 Send SMS ---
  Future<void> _sendFirebaseOtp() async {
    final rawPhone = _phoneController.text.trim();
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
        debugPrint('[CustomerLogin] Firebase phone auto-verified.');
        _completeFirebaseLogin(idToken);
      },
    );
  }

  // --- Firebase Phone Login: Step 2 Verify OTP & Login ---
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
        'role': 'customer',
        ...deviceFields,
      });

      final data = response.data;
      await AuthService.saveToken(data['token']);
      await AuthService.saveUser(Map<String, dynamic>.from(data['user']));
      await AuthService.saveRoles(List<String>.from(data['roles'] ?? ['customer']));
      await PushNotificationService.registerDeviceTokenIfPossible();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in to your customer account',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Mode toggle (Phone OTP vs Password)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _authMode = CustomerAuthMode.phone),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _authMode == CustomerAuthMode.phone ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _authMode == CustomerAuthMode.phone
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android_rounded,
                                size: 18,
                                color: _authMode == CustomerAuthMode.phone ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Phone OTP',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _authMode == CustomerAuthMode.phone ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _authMode = CustomerAuthMode.password),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _authMode == CustomerAuthMode.password ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _authMode == CustomerAuthMode.password
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: _authMode == CustomerAuthMode.password ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _authMode == CustomerAuthMode.password ? AppColors.primary : AppColors.textSecondary,
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

              if (_authMode == CustomerAuthMode.phone) ...[
                // --- Phone Auth Form ---
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_codeSent,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. +2348012345678 or 08012345678',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    suffixIcon: _codeSent
                        ? TextButton(
                            onPressed: () => setState(() {
                              _codeSent = false;
                              _otp = '';
                              _verificationId = null;
                            }),
                            child: const Text('Change', style: TextStyle(fontSize: 13, color: AppColors.primary)),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loading ? null : _sendFirebaseOtp,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Send SMS Verification Code', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Enter 6-digit code sent via SMS:',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 52,
                      fieldWidth: 44,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      activeColor: AppColors.primary,
                      selectedColor: AppColors.primary,
                      inactiveColor: AppColors.border,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_loading || _otp.length != 6) ? null : _verifyOtpAndLogin,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify & Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _resendCountdown > 0 ? null : _sendFirebaseOtp,
                      child: Text(
                        _resendCountdown > 0 ? 'Resend code in ${_resendCountdown}s' : 'Resend SMS code',
                        style: TextStyle(
                          color: _resendCountdown > 0 ? AppColors.textSecondary : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // --- Password Form ---
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _loginController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email or Phone',
                          hintText: 'email@example.com or +234...',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                          child: const Text('Forgot password?', style: TextStyle(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _loading ? null : _loginWithPassword,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Sign In with Password', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerRegisterScreen()),
                    ),
                    child: const Text('Sign up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
