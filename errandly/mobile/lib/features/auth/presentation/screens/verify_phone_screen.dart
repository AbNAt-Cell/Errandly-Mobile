import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../customer/presentation/screens/customer_main_screen.dart';

class VerifyPhoneScreen extends StatefulWidget {
  final String phone;
  const VerifyPhoneScreen({super.key, required this.phone});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  String _otp = '';
  bool _loading = false;

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() => _loading = true);
    try {
      await getIt<ApiClient>().verifyPhone({'phone': widget.phone, 'otp': _otp});
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
          const SnackBar(content: Text('Invalid OTP'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify phone')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Code sent to ${widget.phone}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (v) => _otp = v,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                activeColor: AppColors.primary,
                selectedColor: AppColors.primary,
                inactiveColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify'),
              ),
            ),
            TextButton(
              onPressed: () => getIt<ApiClient>().resendOtp(),
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
