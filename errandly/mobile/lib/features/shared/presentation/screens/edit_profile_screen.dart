import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../../main.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isRunner;

  const EditProfileScreen({super.key, this.isRunner = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        _firstNameCtrl.text = user['first_name']?.toString() ?? '';
        _lastNameCtrl.text = user['last_name']?.toString() ?? '';
        _addressCtrl.text = user['address']?.toString() ?? '';
        _cityCtrl.text = user['city']?.toString() ?? '';
        _stateCtrl.text = user['state']?.toString() ?? '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = getIt<ApiClient>();
      final res = await api.updateProfile({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
      });
      await AuthService.saveUser(Map<String, dynamic>.from(res.data['user']));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorHelper.message(e)), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.isRunner ? AppTheme.runnerTheme : AppTheme.customerTheme,
      child: Scaffold(
        backgroundColor: widget.isRunner ? AppColors.runnerBackground : AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: widget.isRunner ? AppColors.navy : AppColors.surface,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First name')),
                    const SizedBox(height: 12),
                    TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last name')),
                    const SizedBox(height: 12),
                    TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                    const SizedBox(height: 12),
                    TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                    const SizedBox(height: 12),
                    TextField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State')),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
