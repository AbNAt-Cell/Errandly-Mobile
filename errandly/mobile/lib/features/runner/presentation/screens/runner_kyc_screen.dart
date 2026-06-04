import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class RunnerKycScreen extends StatefulWidget {
  const RunnerKycScreen({super.key});

  @override
  State<RunnerKycScreen> createState() => _RunnerKycScreenState();
}

class _RunnerKycScreenState extends State<RunnerKycScreen> {
  final _idNumber = TextEditingController();
  final _nin = TextEditingController();
  final _bvn = TextEditingController();
  final _docUrl = TextEditingController();
  final _selfieUrl = TextEditingController();
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.runnerVerificationStatus();
      setState(() {
        _status = res.data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final api = getIt<ApiClient>();
      await api.submitRunnerKyc({
        'id_type': 'national_id',
        'id_number': _idNumber.text.trim(),
        'nin_number': _nin.text.trim(),
        'bvn_number': _bvn.text.trim(),
        'id_document_url': _docUrl.text.trim(),
        'selfie_url': _selfieUrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC submitted for review'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final approved = _status?['verification_status'] == 'approved';
    return Theme(
      data: AppTheme.runnerTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Runner verification')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : approved
                ? const Center(child: Text('You are verified and can accept errands.', style: TextStyle(color: AppColors.success)))
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListView(
                      children: [
                        Text('Status: ${_status?['verification_status'] ?? 'pending'}', style: const TextStyle(color: AppColors.runnerTextMuted)),
                        const SizedBox(height: 16),
                        _field(_idNumber, 'ID number'),
                        _field(_nin, 'NIN'),
                        _field(_bvn, 'BVN'),
                        _field(_docUrl, 'ID document URL'),
                        _field(_selfieUrl, 'Selfie URL'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit KYC'),
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
