import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class RunnerBankAccountScreen extends StatefulWidget {
  const RunnerBankAccountScreen({super.key});

  @override
  State<RunnerBankAccountScreen> createState() => _RunnerBankAccountScreenState();
}

class _RunnerBankAccountScreenState extends State<RunnerBankAccountScreen> {
  final _bankName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _accountName = TextEditingController();
  final _bankCode = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<ApiClient>().updateBankAccount({
        'bank_name': _bankName.text.trim(),
        'bank_account_number': _accountNumber.text.trim(),
        'bank_account_name': _accountName.text.trim(),
        'bank_code': _bankCode.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account updated'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.runnerTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Bank account')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _field(_bankName, 'Bank name'),
              _field(_accountNumber, 'Account number (10 digits)'),
              _field(_accountName, 'Account name'),
              _field(_bankCode, 'Bank code'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save bank details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppColors.runnerTextMuted)),
      ),
    );
  }
}
