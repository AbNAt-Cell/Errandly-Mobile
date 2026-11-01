import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
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
  String? _profileImageUrl;
  bool _loading = false;
  bool _saving = false;
  bool _uploadingAvatar = false;

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
        _profileImageUrl = user['profile_image']?.toString();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take photo with camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (picked == null) return;

      setState(() => _uploadingAvatar = true);
      final api = getIt<ApiClient>();
      final uploadRes = await api.uploadFile(picked.path, folder: 'avatars');
      final uploadedUrl = uploadRes.data['url']?.toString();

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        setState(() {
          _profileImageUrl = uploadedUrl;
        });
        final updateRes = await api.updateProfile({'profile_image': uploadedUrl});
        if (updateRes.data['user'] != null) {
          await AuthService.saveUser(Map<String, dynamic>.from(updateRes.data['user']));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorHelper.message(e)), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
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
        if (_profileImageUrl != null) 'profile_image': _profileImageUrl,
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: _uploadingAvatar ? null : _pickAvatar,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 3),
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              child: ClipOval(
                                child: _uploadingAvatar
                                    ? const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                                        ),
                                      )
                                    : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: AppConstants.formatImageUrl(_profileImageUrl) ?? _profileImageUrl!,
                                            width: 96,
                                            height: 96,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                                            errorWidget: (_, __, ___) => const Center(child: Icon(Icons.person, size: 48, color: AppColors.primary)),
                                          )
                                        : const Center(child: Icon(Icons.person, size: 48, color: AppColors.primary)),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _uploadingAvatar ? null : _pickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _uploadingAvatar ? null : _pickAvatar,
                      child: const Text('Change Profile Photo', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First name')),
                    const SizedBox(height: 12),
                    TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last name')),
                    const SizedBox(height: 12),
                    TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                    const SizedBox(height: 12),
                    TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                    const SizedBox(height: 12),
                    TextField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State')),
                    const SizedBox(height: 32),
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
