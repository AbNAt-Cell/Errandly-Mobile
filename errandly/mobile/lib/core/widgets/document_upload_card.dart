import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/api_error_helper.dart';
import '../../main.dart';

class DocumentUploadCard extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? initialUrl;
  final String folder;
  final bool isRequired;
  final bool allowPdf;
  final ValueChanged<String> onUploaded;
  final VoidCallback? onRemoved;

  const DocumentUploadCard({
    super.key,
    required this.label,
    required this.hint,
    this.icon = Icons.upload_file_rounded,
    this.initialUrl,
    this.folder = 'kyc',
    this.isRequired = true,
    this.allowPdf = true,
    required this.onUploaded,
    this.onRemoved,
  });

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  String? _uploadedUrl;
  String? _localPreviewPath;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _uploadedUrl = widget.initialUrl;
  }

  @override
  void didUpdateWidget(covariant DocumentUploadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != oldWidget.initialUrl && widget.initialUrl != null) {
      _uploadedUrl = widget.initialUrl;
    }
  }

  Future<void> _handleUpload(String filePath) async {
    setState(() {
      _localPreviewPath = filePath;
      _isUploading = true;
    });

    try {
      final api = getIt<ApiClient>();
      final res = await api.uploadFile(filePath, folder: widget.folder);
      final rawUrl = (res.data['url'] ?? res.data['data']?['url'])?.toString();

      if (rawUrl == null || rawUrl.isEmpty) {
        throw Exception('Upload succeeded but no file URL was returned.');
      }

      setState(() {
        _uploadedUrl = rawUrl;
      });

      widget.onUploaded(rawUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.label} uploaded successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorHelper.message(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showPickerSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload ${widget.label}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a source to upload your file or document',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Take photo with camera', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (picked != null) {
                    _handleUpload(picked.path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                ),
                title: const Text('Choose from photo gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (picked != null) {
                    _handleUpload(picked.path);
                  }
                },
              ),
              if (widget.allowPdf)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.purple),
                  ),
                  title: const Text('Pick PDF document or file', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                    );
                    if (result != null && result.files.single.path != null) {
                      _handleUpload(result.files.single.path!);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = _uploadedUrl != null && _uploadedUrl!.isNotEmpty;
    final formattedUrl = AppConstants.formatImageUrl(_uploadedUrl) ?? _uploadedUrl;
    final isPdf = (_uploadedUrl?.toLowerCase().endsWith('.pdf') == true) ||
        (_localPreviewPath?.toLowerCase().endsWith('.pdf') == true);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (widget.isRequired)
                const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (hasFile && !_isUploading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Ready', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: _isUploading ? null : () => _showPickerSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasFile
                    ? (isDark ? const Color(0xFF1F222A) : Colors.white)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasFile
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant,
                  width: hasFile ? 1.5 : 1.0,
                ),
              ),
              child: _isUploading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Uploading file to secure storage...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    )
                  : hasFile
                      ? Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 56,
                                height: 56,
                                color: colorScheme.surfaceContainerHighest,
                                child: isPdf
                                    ? const Center(
                                        child: Icon(Icons.picture_as_pdf_rounded, color: Colors.purple, size: 28),
                                      )
                                    : _localPreviewPath != null && File(_localPreviewPath!).existsSync()
                                        ? Image.file(File(_localPreviewPath!), fit: BoxFit.cover)
                                        : (formattedUrl != null && formattedUrl.isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl: formattedUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                                errorWidget: (_, __, ___) => const Icon(Icons.image_rounded),
                                              )
                                            : const Icon(Icons.image_rounded),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPdf ? 'PDF Document Uploaded' : 'Photo Uploaded',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to change or replace file',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                              ),
                              onPressed: () => _showPickerSheet(context),
                              child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(widget.icon, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.hint,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.allowPdf ? 'Camera, photo gallery or PDF' : 'Camera or photo gallery',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
