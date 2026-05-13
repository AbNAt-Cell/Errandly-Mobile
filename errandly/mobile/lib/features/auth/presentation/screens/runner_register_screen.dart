import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../runner/presentation/screens/runner_main_screen.dart';

class RunnerRegisterScreen extends StatefulWidget {
  const RunnerRegisterScreen({super.key});

  @override
  State<RunnerRegisterScreen> createState() => _RunnerRegisterScreenState();
}

class _RunnerRegisterScreenState extends State<RunnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _transportType = 'motorcycle';
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = getIt<ApiClient>();
      final response = await api.registerRunner({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'password_confirmation': _passwordCtrl.text,
        'city': 'Uyo',
        'state': 'Akwa Ibom',
        'transport_type': _transportType,
      });

      final data = response.data;
      await AuthService.saveToken(data['token']);
      await AuthService.saveUser(Map<String, dynamic>.from(data['user']));
      await AuthService.saveRoles(['runner']);

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
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Become a Runner', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Complete KYC verification after signup to start earning', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                  const SizedBox(height: 24),

                  _darkField(_firstNameCtrl, 'First Name', Icons.person_outline),
                  const SizedBox(height: 12),
                  _darkField(_lastNameCtrl, 'Last Name', Icons.person_outline),
                  const SizedBox(height: 12),
                  _darkField(_emailCtrl, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _darkField(_phoneCtrl, 'Phone Number', Icons.phone_outlined, type: TextInputType.phone, hint: '+2348100000000'),
                  const SizedBox(height: 12),
                  _darkField(_passwordCtrl, 'Password', Icons.lock_outline, obscure: true),
                  const SizedBox(height: 16),

                  Text('Transport Type', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _transportChip('foot', '🚶 On Foot'),
                      _transportChip('bicycle', '🚲 Bicycle'),
                      _transportChip('motorcycle', '🏍️ Motorcycle'),
                      _transportChip('car', '🚗 Car'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Text(
                      '⚠️ After registration, you must complete identity verification (KYC) including government ID, selfie, and bank account before accepting errands.',
                      style: TextStyle(color: AppColors.primaryLight, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Create Runner Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _darkField(TextEditingController ctrl, String label, IconData icon, {
    TextInputType? type, String? hint, bool obscure = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: AppColors.navyLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
    );
  }

  Widget _transportChip(String value, String label) {
    final selected = _transportType == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white.withOpacity(0.7), fontSize: 13)),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.navyLight,
      side: BorderSide(color: selected ? AppColors.primary : Colors.white.withOpacity(0.1)),
      onSelected: (_) => setState(() => _transportType = value),
    );
  }
}
