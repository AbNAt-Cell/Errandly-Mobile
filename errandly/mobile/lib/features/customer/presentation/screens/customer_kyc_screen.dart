import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
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
          SnackBar(content: const Text('KYC submitted for review'), backgroundColor: Colors.green.shade600),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final kycStatus = _status?['kyc_status'] ?? 'pending';
    final approved = kycStatus == 'approved';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Identity Verification', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : approved
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.green.shade600.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.verified_user_rounded, size: 64, color: Colors.green.shade600),
                        ),
                        const SizedBox(height: 24),
                        Text('Identity Verified', style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text('Your identity is verified and your account is in good standing.', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kycStatus == 'rejected' ? colorScheme.error.withOpacity(0.1) : Colors.orange.shade600.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kycStatus == 'rejected' ? colorScheme.error.withOpacity(0.3) : Colors.orange.shade600.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(kycStatus == 'rejected' ? Icons.cancel_rounded : Icons.info_outline_rounded, color: kycStatus == 'rejected' ? colorScheme.error : Colors.orange.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Verification Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kycStatus == 'rejected' ? colorScheme.error : Colors.orange.shade600)),
                                Text(kycStatus.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kycStatus == 'rejected' ? colorScheme.error : Colors.orange.shade600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text('Verification Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _idType,
                          isExpanded: true,
                          dropdownColor: colorScheme.surface,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
                          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16),
                          items: const [
                            DropdownMenuItem(value: 'national_id', child: Text('National ID')),
                            DropdownMenuItem(value: 'drivers_license', child: Text("Driver's license")),
                            DropdownMenuItem(value: 'passport', child: Text('Passport')),
                            DropdownMenuItem(value: 'voters_card', child: Text("Voter's card")),
                          ],
                          onChanged: (v) => setState(() => _idType = v ?? _idType),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _field(_idNumber, 'ID Number', colorScheme),
                    _field(_docUrl, 'ID Document URL', colorScheme),
                    _field(_selfieUrl, 'Selfie URL', colorScheme),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting 
                            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 3)) 
                            : const Text('Submit Verification', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }

  Widget _field(TextEditingController c, String label, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
