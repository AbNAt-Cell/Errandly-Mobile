import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../runner/presentation/screens/runner_main_screen.dart';

class RunnerLoginScreen extends StatefulWidget {
  const RunnerLoginScreen({super.key});

  @override
  State<RunnerLoginScreen> createState() => _RunnerLoginScreenState();
}

class _RunnerLoginScreenState extends State<RunnerLoginScreen> {
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  Future<void> _login() async {
    if (_loginCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    try {
      final api = getIt<ApiClient>();
      final response = await api.login({
        'login': _loginCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });

      final data = response.data;
      await AuthService.saveToken(data['token']);
      await AuthService.saveUser(Map<String, dynamic>.from(data['user']));
      await AuthService.saveRoles(List<String>.from(data['roles'] ?? []));

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
          const SnackBar(content: Text('Invalid credentials.'), backgroundColor: AppColors.danger),
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
                const SizedBox(height: 32),

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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Sign In as Runner'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
