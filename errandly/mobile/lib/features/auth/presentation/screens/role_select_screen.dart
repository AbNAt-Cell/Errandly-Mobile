import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'customer_login_screen.dart';
import 'customer_register_screen.dart';
import 'runner_login_screen.dart';
import 'runner_register_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              const Text(
                'Errandly',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your trusted local errand partner',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Role cards
              _RoleCard(
                emoji: '🙋',
                title: 'I need errands done',
                subtitle: 'Post tasks and get them done by verified runners',
                onLogin: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerLoginScreen())),
                onRegister: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerRegisterScreen())),
                accentColor: AppColors.primary,
              ),
              const SizedBox(height: 16),
              _RoleCard(
                emoji: '🏃',
                title: 'I want to be a Runner',
                subtitle: 'Accept errands, earn money in your neighborhood',
                onLogin: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerLoginScreen())),
                onRegister: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerRegisterScreen())),
                accentColor: AppColors.navyLight,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final Color accentColor;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onLogin,
    required this.onRegister,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Log In', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
