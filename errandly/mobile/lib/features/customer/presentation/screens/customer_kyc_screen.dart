import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class CustomerKycScreen extends StatefulWidget {
  const CustomerKycScreen({super.key});

  @override
  State<CustomerKycScreen> createState() => _CustomerKycScreenState();
}

class _CustomerKycScreenState extends State<CustomerKycScreen> {
  final _idNumber = TextEditingController();
  final _docUrl = TextEditingController();
  final _selfieUrl = TextEditingController();
  String _idType = 'national_id';
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
      final res = await getIt<ApiClient>().kycStatus();
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
      await getIt<ApiClient>().submitKyc({
        'id_type': _idType,
        'id_number': _idNumber.text.trim(),
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
    final kycStatus = _status?['kyc_status'] ?? 'pending';
    final approved = kycStatus == 'approved';

    return Scaffold(
      appBar: AppBar(title: const Text('Identity verification')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : approved
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Your identity is verified.', style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('Status: $kycStatus', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _idType,
                      decoration: const InputDecoration(labelText: 'ID type'),
                      items: const [
                        DropdownMenuItem(value: 'national_id', child: Text('National ID')),
                        DropdownMenuItem(value: 'drivers_license', child: Text("Driver's license")),
                        DropdownMenuItem(value: 'passport', child: Text('Passport')),
                        DropdownMenuItem(value: 'voters_card', child: Text("Voter's card")),
                      ],
                      onChanged: (v) => setState(() => _idType = v ?? _idType),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _idNumber, decoration: const InputDecoration(labelText: 'ID number')),
                    const SizedBox(height: 12),
                    TextField(controller: _docUrl, decoration: const InputDecoration(labelText: 'ID document URL')),
                    const SizedBox(height: 12),
                    TextField(controller: _selfieUrl, decoration: const InputDecoration(labelText: 'Selfie URL')),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit for review'),
                    ),
                  ],
                ),
    );
  }
}
