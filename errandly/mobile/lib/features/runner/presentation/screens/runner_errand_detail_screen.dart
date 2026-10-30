import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/audio_alert_service.dart';
import '../../../../core/services/runner_location_tracker.dart';
import '../../../../main.dart';
import '../../../customer/presentation/screens/customer_message_thread_screen.dart';
import '../../../shared/presentation/screens/voice_call_screen.dart';

class RunnerErrandDetailScreen extends StatefulWidget {
  final String errandPublicId;
  const RunnerErrandDetailScreen({super.key, required this.errandPublicId});

  @override
  State<RunnerErrandDetailScreen> createState() => _RunnerErrandDetailScreenState();
}

class _RunnerErrandDetailScreenState extends State<RunnerErrandDetailScreen> {
  Map<String, dynamic>? _errand;
  bool _loading = true;
  String? _subscribedErrandId;
  void Function(String, dynamic)? _realtimeListener;
  bool _isMapExpanded = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _setupRealtimeSubscription(String errandId) {
    if (_subscribedErrandId == errandId) return;
    _cleanupRealtime();
    _subscribedErrandId = errandId;
    _realtimeListener = (event, data) {
      if (!mounted) return;
      if (event == 'ErrandStatusUpdated') {
        _load();
        if (data is Map && data['status'] == 'completed') {
          AudioAlertService.instance.playCustomerChime();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 Errand confirmed complete! Escrow payout released.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    };
    RealtimeService.instance.subscribeErrand(
      errandId: errandId,
      onEvent: _realtimeListener!,
    );
  }

  void _cleanupRealtime() {
    if (_subscribedErrandId != null && _realtimeListener != null) {
      RealtimeService.instance.unsubscribeErrand(
        errandId: _subscribedErrandId!,
        onEvent: _realtimeListener!,
      );
      _subscribedErrandId = null;
      _realtimeListener = null;
    }
  }

  @override
  void dispose() {
    _cleanupRealtime();
    final status = _errand?['status']?.toString() ?? '';
    if (['completed', 'cancelled', 'disputed'].contains(status)) {
      RunnerLocationTracker.instance.stopTracking();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.getRunnerErrand(widget.errandPublicId);
      setState(() {
        _errand = res.data;
        _loading = false;
      });

      if (_errand != null && _errand!['id'] != null) {
        _setupRealtimeSubscription(_errand!['id'].toString());
      }

      if (_errand != null) {
        final status = _errand!['status']?.toString() ?? '';
        final isTrackingStatus = [
          'accepted',
          'assigned',
          'runner_en_route',
          'arrived',
          'item_picked',
          'in_progress',
        ].contains(status);

        if (isTrackingStatus) {
          RunnerLocationTracker.instance.startTracking(errandPublicId: widget.errandPublicId);
        } else if (['completed', 'cancelled', 'disputed'].contains(status)) {
          RunnerLocationTracker.instance.stopTracking();
        }
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markArrived() async {
    final api = getIt<ApiClient>();
    await api.markArrived(widget.errandPublicId);
    RunnerLocationTracker.instance.startTracking(errandPublicId: widget.errandPublicId);
    _load();
  }

  Future<void> _verifyPickupOtp(ColorScheme colorScheme) async {
    final otp = await _showOtpDialog('Enter Pickup OTP', colorScheme);
    if (otp == null || otp.length != 6) return;
    try {
      final api = getIt<ApiClient>();
      await api.verifyPickupOtp(widget.errandPublicId, otp);
      RunnerLocationTracker.instance.startTracking(errandPublicId: widget.errandPublicId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup verified! You can now start the errand.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid OTP. Please check with customer.'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _startErrand() async {
    final api = getIt<ApiClient>();
    await api.startErrand(widget.errandPublicId);
    RunnerLocationTracker.instance.startTracking(errandPublicId: widget.errandPublicId);
    _load();
  }

  Future<void> _submitProof(ColorScheme colorScheme) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt_rounded, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Proof of Delivery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload image proof of delivery or purchase receipt to complete the errand and request escrow payout.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            _ProofOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Delivery Photo',
              subtitle: 'Open camera to capture the delivered package/item',
              colorScheme: colorScheme,
              onTap: () {
                Navigator.pop(ctx);
                _pickImageProof(ImageSource.camera, 'photo', colorScheme);
              },
            ),
            const SizedBox(height: 12),
            _ProofOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose Photo from Gallery',
              subtitle: 'Select delivery completion photo from gallery',
              colorScheme: colorScheme,
              onTap: () {
                Navigator.pop(ctx);
                _pickImageProof(ImageSource.gallery, 'photo', colorScheme);
              },
            ),
            const SizedBox(height: 12),
            _ProofOptionTile(
              icon: Icons.receipt_long_rounded,
              title: 'Upload Purchase Receipt',
              subtitle: 'Attach item purchase receipt or invoice image',
              colorScheme: colorScheme,
              onTap: () {
                Navigator.pop(ctx);
                _pickReceiptProof(colorScheme);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceiptProof(ColorScheme colorScheme) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attach Receipt Image', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('How would you like to provide the receipt?', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickImageProof(ImageSource.camera, 'receipt', colorScheme);
                    },
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickImageProof(ImageSource.gallery, 'receipt', colorScheme);
                    },
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageProof(ImageSource source, String type, ColorScheme colorScheme) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600, maxHeight: 1600);
      if (picked == null || !mounted) return;

      _showProofPreviewSheet(picked.path, type, colorScheme);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera or gallery: $e'), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  Future<void> _showProofPreviewSheet(String filePath, String type, ColorScheme colorScheme) async {
    final notesController = TextEditingController();
    bool isUploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type == 'receipt' ? 'PURCHASE RECEIPT' : 'DELIVERY PHOTO',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colorScheme.primary),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: isUploading ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.black12,
                      child: Image.file(
                        File(filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Notes (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    enabled: !isUploading,
                    maxLines: 2,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: type == 'receipt' ? 'e.g., Total spent ₦4,500 from supermarket' : 'e.g., Handed package directly to recipient',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              setSheetState(() => isUploading = true);
                              try {
                                final api = getIt<ApiClient>();
                                await api.submitProofFile(
                                  widget.errandPublicId,
                                  filePath: filePath,
                                  type: type,
                                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(child: Text('Proof uploaded successfully! Awaiting customer confirmation.')),
                                        ],
                                      ),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                  _load();
                                }
                              } catch (e) {
                                setSheetState(() => isUploading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to upload proof: $e'), backgroundColor: colorScheme.error),
                                  );
                                }
                              }
                            },
                      icon: isUploading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_rounded, size: 20),
                      label: Text(
                        isUploading ? 'Uploading Proof...' : 'Submit Proof & Request Payout',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancelErrand(ColorScheme colorScheme) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        title: Text('Cancel Errand?', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please specify the reason for cancelling this errand:', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: reason,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'e.g., Vehicle breakdown, unable to contact customer',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Errand', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Errand', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || reason.text.trim().isEmpty) return;
    try {
      await getIt<ApiClient>().cancelErrandRunner(widget.errandPublicId, reason.text.trim());
      RunnerLocationTracker.instance.stopTracking();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Could not cancel errand'), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  Future<void> _triggerPanic(ColorScheme colorScheme) async {
    try {
      final api = getIt<ApiClient>();
      await api.runnerPanic(widget.errandPublicId, {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panic alert sent. Errand Admin has been notified.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to send panic alert.'), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  Future<String?> _showOtpDialog(String title, ColorScheme colorScheme) async {
    String otp = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        title: Text('Verify Pickup Passcode', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask the sender or customer at pickup for the 6-digit Customer Pickup Passcode shown on their Errandly app:',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (v) => otp = v,
              textStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: 46,
                fieldWidth: 38,
                fieldOuterPadding: const EdgeInsets.symmetric(horizontal: 2),
                activeColor: colorScheme.primary,
                selectedColor: colorScheme.primary,
                inactiveColor: colorScheme.outlineVariant,
                activeFillColor: colorScheme.surfaceContainerHighest,
                selectedFillColor: colorScheme.surfaceContainerHighest,
                inactiveFillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              enableActiveFill: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, otp),
            child: const Text('Verify Pickup', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }
    if (_errand == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Errand not found', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
            ],
          ),
        ),
      );
    }

    final status = _errand!['status'] ?? '';
    final statusLabel = AppConstants.statusLabels[status] ?? status;
    final customer = _errand!['customer'];
    final pickupLat = (_errand?['pickup_latitude'] as num?)?.toDouble() ?? AppConstants.defaultLat;
    final pickupLng = (_errand?['pickup_longitude'] as num?)?.toDouble() ?? AppConstants.defaultLng;
    final rawDestLat = (_errand?['destination_latitude'] as num?)?.toDouble();
    final rawDestLng = (_errand?['destination_longitude'] as num?)?.toDouble();
    final hasDest = rawDestLat != null && rawDestLng != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(statusLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colorScheme.onSurface)),
          ],
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          if (customer != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VoiceCallScreen(
                        errandId: widget.errandPublicId,
                        errandTitle: _errand!['title'] ?? 'Errand',
                        contactName: customer['full_name'] ?? 'Customer',
                        contactAvatar: customer['avatar_url'] as String?,
                        isIncoming: false,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 20),
                tooltip: 'In-App Voice Call',
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            ),
            child: IconButton(
              onPressed: () => _triggerPanic(colorScheme),
              icon: const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Panic Button',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map view with Live GPS tracking indicator & expand toggle
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isMapExpanded ? MediaQuery.of(context).size.height * 0.50 : 230,
            child: Stack(
              children: [
                ValueListenableBuilder<Position?>(
                  valueListenable: RunnerLocationTracker.instance.currentPositionNotifier,
                  builder: (context, currentPos, _) {
                    final runnerPos = currentPos != null ? LatLng(currentPos.latitude, currentPos.longitude) : null;
                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: runnerPos ?? LatLng(pickupLat, pickupLng),
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                        MarkerLayer(markers: [
                          // Pickup / Venue Pin
                          Marker(
                            point: LatLng(pickupLat, pickupLng),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: !hasDest ? const Color(0xFF8B5CF6) : colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: Icon(
                                !hasDest ? Icons.place_rounded : Icons.radio_button_checked_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          // Intermediate stops
                          if (_errand?['stops'] is List)
                            ...(_errand!['stops'] as List).asMap().entries.map((entry) {
                              final idx = entry.key;
                              final st = entry.value;
                              if (st is Map && st['latitude'] != null && st['longitude'] != null) {
                                final sLat = (st['latitude'] as num).toDouble();
                                final sLng = (st['longitude'] as num).toDouble();
                                return Marker(
                                  point: LatLng(sLat, sLng),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                    ),
                                    child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }
                              return const Marker(point: LatLng(0, 0), child: SizedBox());
                            }).where((m) => m.point.latitude != 0),
                          // Destination Pin (only if set)
                          if (hasDest)
                            Marker(
                              point: LatLng(rawDestLat, rawDestLng),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          if (runnerPos != null)
                            Marker(
                              point: runnerPos,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
                                ),
                                child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                        ]),
                      ],
                    );
                  },
                ),
                // Expand / Collapse map toggle button
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: IconButton(
                      icon: Icon(_isMapExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: colorScheme.onSurface, size: 20),
                      tooltip: _isMapExpanded ? 'Collapse Map' : 'Expand Map',
                      onPressed: () {
                        setState(() => _isMapExpanded = !_isMapExpanded);
                      },
                    ),
                  ),
                ),
                // Live GPS broadcasting pill
                Positioned(
                  top: 12,
                  right: 12,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: RunnerLocationTracker.instance.isTrackingNotifier,
                    builder: (context, isTracking, _) {
                      if (!isTracking) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.satellite_alt_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'GPS Live',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Description
                  Text(
                    _errand!['title'] ?? '',
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.25),
                  ),
                  if ((_errand!['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errand!['description'] ?? '',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, height: 1.45),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Customer Contact Card
                  if (customer != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                            ),
                            child: CircleAvatar(
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                              radius: 22,
                              child: Icon(Icons.person, color: colorScheme.primary, size: 24),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer['full_name'] ?? 'Customer',
                                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Errand Creator',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: IconButton(
                              onPressed: () {
                                final phone = customer['phone'] as String?;
                                if (phone != null && phone.isNotEmpty) {
                                  UrlHelper.open(context, 'tel:$phone');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Customer phone number not available.')),
                                  );
                                }
                              },
                              icon: Icon(Icons.phone_rounded, color: colorScheme.primary, size: 20),
                              tooltip: 'Cellular Call',
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => VoiceCallScreen(
                                      errandId: widget.errandPublicId,
                                      errandTitle: _errand!['title'] ?? 'Errand',
                                      contactName: customer['full_name'] ?? 'Customer',
                                      contactAvatar: customer['avatar_url'] as String?,
                                      isIncoming: false,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 20),
                              tooltip: 'In-App Voice Call',
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerMessageThreadScreen(publicId: widget.errandPublicId),
                                  ),
                                );
                              },
                              icon: Icon(Icons.chat_bubble_rounded, color: colorScheme.onPrimary, size: 20),
                              tooltip: 'Chat with Customer',
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Locations Timeline Card
                  Builder(
                    builder: (context) {
                      final rawDest = _errand!['destination_address']?.toString().trim();
                      final hasValidDest = rawDest != null &&
                          rawDest.isNotEmpty &&
                          rawDest != 'Destination not specified';
                      final workflowType = _errand!['workflow_type']?.toString();
                      final isSingleWorkflow = workflowType == 'queue_waiting' || workflowType == 'single_location';
                      final hasTwoLocations = !isSingleWorkflow && hasValidDest;

                      return _TimelineLocationsCard(
                        pickup: _errand!['pickup_address'] ?? 'Location not specified',
                        destination: _errand!['destination_address']?.toString(),
                        hasTwoLocations: hasTwoLocations,
                        stops: _errand!['stops'] is List ? (_errand!['stops'] as List) : null,
                        colorScheme: colorScheme,
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Earnings Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR GUARANTEED PAYOUT',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦${_errand!['runner_earnings'] ?? 0}',
                              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('IN ESCROW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action buttons based on status
                  ..._buildActions(status, colorScheme),

                  if (['accepted', 'runner_en_route', 'item_picked'].contains(status)) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _cancelErrand(colorScheme),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Cancel Errand', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(String status, ColorScheme colorScheme) {
    return switch (status) {
      'accepted' => [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _markArrived,
            icon: const Icon(Icons.directions_run_rounded, size: 22),
            label: const Text('I Have Arrived at Pickup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
      'runner_en_route' => [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _verifyPickupOtp(colorScheme),
            icon: const Icon(Icons.pin_rounded, size: 22),
            label: const Text('Enter Pickup OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
      'item_picked' => [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startErrand,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text('Start Errand (In Transit)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
      'in_progress' => [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _submitProof(colorScheme),
            icon: const Icon(Icons.camera_alt_rounded, size: 22),
            label: const Text('Submit Proof & Mark Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
      'awaiting_confirmation' => [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Color(0xFF3B82F6), size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Proof Submitted!', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Waiting for customer to verify OTP and confirm delivery.', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      _ => [],
    };
  }
}

class _TimelineLocationsCard extends StatelessWidget {
  final String pickup;
  final String? destination;
  final bool hasTwoLocations;
  final List<dynamic>? stops;
  final ColorScheme colorScheme;

  const _TimelineLocationsCard({
    required this.pickup,
    this.destination,
    this.hasTwoLocations = true,
    this.stops,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasTwoLocations) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pickup,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final validStops = stops?.where((s) => s is Map && s['address'] != null).toList() ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.radio_button_checked_rounded, color: colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PICKUP LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(pickup, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 24, color: colorScheme.outlineVariant),
            ),
          ),
          for (int i = 0; i < validStops.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pin_drop_rounded, color: Color(0xFF3B82F6), size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STOP ${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(validStops[i]['address']?.toString() ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 2, height: 24, color: colorScheme.outlineVariant),
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DESTINATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFEF4444), letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(destination ?? 'Destination not specified', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProofOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ProofOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurfaceVariant, size: 14),
          ],
        ),
      ),
    );
  }
}
