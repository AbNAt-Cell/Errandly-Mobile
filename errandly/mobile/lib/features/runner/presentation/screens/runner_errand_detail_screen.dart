import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/audio_alert_service.dart';
import '../../../../main.dart';
import '../../../customer/presentation/screens/customer_message_thread_screen.dart';

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
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markArrived() async {
    final api = getIt<ApiClient>();
    await api.markArrived(widget.errandPublicId);
    _load();
  }

  Future<void> _verifyPickupOtp(ColorScheme colorScheme) async {
    final otp = await _showOtpDialog('Enter Pickup OTP', colorScheme);
    if (otp == null || otp.length != 6) return;
    try {
      final api = getIt<ApiClient>();
      await api.verifyPickupOtp(widget.errandPublicId, otp);
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
              'Upload proof of delivery or receipt to complete the errand and request escrow payout.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            _ProofOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Upload Photo Proof',
              subtitle: 'Take or choose a delivery completion photo',
              colorScheme: colorScheme,
              onTap: () async {
                Navigator.pop(ctx);
                final api = getIt<ApiClient>();
                await api.submitProof(widget.errandPublicId, {'type': 'photo', 'notes': 'Delivery completed'});
                _load();
              },
            ),
            const SizedBox(height: 12),
            _ProofOptionTile(
              icon: Icons.receipt_long_rounded,
              title: 'Upload Purchase Receipt',
              subtitle: 'Attach item purchase receipt or invoice',
              colorScheme: colorScheme,
              onTap: () async {
                Navigator.pop(ctx);
                final api = getIt<ApiClient>();
                await api.submitProof(widget.errandPublicId, {'type': 'receipt', 'notes': 'Receipt attached'});
                _load();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
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
            content: Text('Panic alert sent. Errandly Admin has been notified.'),
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
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the 6-digit verification code provided by the sender at pickup:', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (v) => otp = v,
              textStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 48,
                fieldWidth: 40,
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
    final destLat = (_errand?['destination_latitude'] as num?)?.toDouble() ?? AppConstants.defaultLat;
    final destLng = (_errand?['destination_longitude'] as num?)?.toDouble() ?? AppConstants.defaultLng;

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
          // Map view
          SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(initialCenter: LatLng(pickupLat, pickupLng), initialZoom: 14),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(pickupLat, pickupLng),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.radio_button_checked_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  Marker(
                    point: LatLng(destLat, destLng),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
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
                              tooltip: 'Call Customer',
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
                  _TimelineLocationsCard(
                    pickup: _errand!['pickup_address'] ?? 'Pickup location not specified',
                    destination: _errand!['destination_address'] ?? 'Destination not specified',
                    colorScheme: colorScheme,
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
  final String destination;
  final ColorScheme colorScheme;

  const _TimelineLocationsCard({required this.pickup, required this.destination, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
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
                    Text(destination, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface, height: 1.35)),
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
