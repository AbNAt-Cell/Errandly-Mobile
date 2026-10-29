import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../../main.dart';
import '../../../customer/presentation/screens/customer_main_screen.dart';
import '../../../runner/presentation/screens/runner_main_screen.dart';

class VerifyPhoneScreen extends StatefulWidget {
  final String phone;
  const VerifyPhoneScreen({super.key, required this.phone});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  String _otp = '';
  bool _loading = false;
  bool _sendingCode = true;
  String? _verificationId;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startFirebasePhoneVerification();
  }

  @override
  void dispose() {
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

  Future<void> _startFirebasePhoneVerification() async {
    setState(() => _sendingCode = true);
    await FirebaseAuthService.instance.sendPhoneVerification(
      phoneNumber: widget.phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _sendingCode = false;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent via SMS.'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _sendingCode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.danger),
        );
      },
      onAutoVerified: (idToken) {
        if (!mounted) return;
        debugPrint('[VerifyPhoneScreen] Auto-verification triggered with idToken.');
        _submitVerification(idToken: idToken);
      },
    );
  }

  Future<void> _submitVerification({String? idToken}) async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();

      if (idToken != null) {
        // Direct ID token from auto-retrieval
        final response = await api.verifyFirebasePhone({
          'id_token': idToken,
          'phone': widget.phone,
        });
        if (response.data['user'] != null) {
          await AuthService.saveUser(Map<String, dynamic>.from(response.data['user']));
        }
      } else if (_verificationId != null) {
        // Verify SMS code with Firebase Auth
        final token = await FirebaseAuthService.instance.verifySmsCodeAndGetIdToken(
          verificationId: _verificationId!,
          smsCode: _otp,
        );
        final response = await api.verifyFirebasePhone({
          'id_token': token,
          'phone': widget.phone,
        });
        if (response.data['user'] != null) {
          await AuthService.saveUser(Map<String, dynamic>.from(response.data['user']));
        }
      } else {
        // Fallback to local OTP
        await api.verifyPhone({'phone': widget.phone, 'otp': _otp});
      }

      final isRunner = await AuthService.isRunner();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number verified!'), backgroundColor: AppColors.success),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => isRunner ? const RunnerMainScreen() : const CustomerMainScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Phone'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryFaded,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_android, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Phone Verification',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit verification code to:\n${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.4),
              ),
              if (_sendingCode) ...[
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Sending SMS via Firebase...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              PinCodeTextField(
                appContext: context,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
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
                enableActiveFill: false,
                onChanged: (v) {
                  setState(() => _otp = v);
                  if (v.length == 6) {
                    _submitVerification();
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_loading || _otp.length != 6) ? null : () => _submitVerification(),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify Phone', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_resendCountdown > 0 || _sendingCode)
                    ? null
                    : () => _startFirebasePhoneVerification(),
                child: Text(
                  _resendCountdown > 0
                      ? 'Resend code in ${_resendCountdown}s'
                      : 'Resend Verification Code',
                  style: TextStyle(
                    color: (_resendCountdown > 0 || _sendingCode) ? AppColors.textSecondary : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
