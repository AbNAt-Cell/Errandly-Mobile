import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../main.dart';

class RunnerErrandDetailScreen extends StatefulWidget {
  final String errandPublicId;
  const RunnerErrandDetailScreen({super.key, required this.errandPublicId});

  @override
  State<RunnerErrandDetailScreen> createState() => _RunnerErrandDetailScreenState();
}

class _RunnerErrandDetailScreenState extends State<RunnerErrandDetailScreen> {
  Map<String, dynamic>? _errand;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.getRunnerErrand(widget.errandPublicId);
      setState(() {
        _errand = res.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markArrived() async {
    final api = getIt<ApiClient>();
    await api.markArrived(widget.errandPublicId);
    _load();
  }

  Future<void> _verifyPickupOtp() async {
    final otp = await _showOtpDialog('Enter Pickup OTP');
    if (otp == null || otp.length != 6) return;
    try {
      final api = getIt<ApiClient>();
      await api.verifyPickupOtp(widget.errandPublicId, otp);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pickup verified! You can now start the errand.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _startErrand() async {
    final api = getIt<ApiClient>();
    await api.startErrand(widget.errandPublicId);
    _load();
  }

  Future<void> _submitProof() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit Proof', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Upload Photo Proof'),
              onTap: () async {
                Navigator.pop(ctx);
                final api = getIt<ApiClient>();
                await api.submitProof(widget.errandPublicId, {'type': 'photo', 'notes': 'Delivery completed'});
                _load();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_rounded, color: AppColors.primary),
              title: const Text('Upload Receipt'),
              onTap: () async {
                Navigator.pop(ctx);
                final api = getIt<ApiClient>();
                await api.submitProof(widget.errandPublicId, {'type': 'receipt', 'notes': 'Receipt attached'});
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelErrand() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel errand?'),
        content: TextField(controller: reason, decoration: const InputDecoration(hintText: 'Reason')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
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
          const SnackBar(content: Text('Could not cancel'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _triggerPanic() async {
    try {
      final api = getIt<ApiClient>();
      await api.runnerPanic(widget.errandPublicId, {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panic alert sent. Admin has been notified.'), backgroundColor: AppColors.danger),
        );
        _load();
      }
    } catch (e) {}
  }

  Future<String?> _showOtpDialog(String title) async {
    String otp = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: PinCodeTextField(
          appContext: context,
          length: 6,
          onChanged: (v) => otp = v,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            activeColor: AppColors.primary,
            selectedColor: AppColors.primary,
            inactiveColor: AppColors.border,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, otp), child: const Text('Verify')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Theme(data: AppTheme.runnerTheme, child: const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))));
    if (_errand == null) return Theme(data: AppTheme.runnerTheme, child: const Scaffold(body: Center(child: Text('Not found'))));

    final status = _errand!['status'] ?? '';
    final statusLabel = AppConstants.statusLabels[status] ?? status;
    final customer = _errand!['customer'];
    final pickupLat = (_errand?['pickup_latitude'] as num?)?.toDouble() ?? AppConstants.defaultLat;
    final pickupLng = (_errand?['pickup_longitude'] as num?)?.toDouble() ?? AppConstants.defaultLng;
    final destLat = (_errand?['destination_latitude'] as num?)?.toDouble() ?? AppConstants.defaultLat;
    final destLng = (_errand?['destination_longitude'] as num?)?.toDouble() ?? AppConstants.defaultLng;

    return Theme(
      data: AppTheme.runnerTheme,
      child: Scaffold(
        backgroundColor: AppColors.runnerBackground,
        appBar: AppBar(
          title: Text(statusLabel),
          actions: [
            IconButton(
              onPressed: _triggerPanic,
              icon: const Icon(Icons.emergency_rounded, color: AppColors.danger),
              tooltip: 'Panic',
            ),
          ],
        ),
        body: Column(
          children: [
            // Map
            SizedBox(
              height: 240,
              child: FlutterMap(
                options: MapOptions(initialCenter: LatLng(pickupLat, pickupLng), initialZoom: 14),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  MarkerLayer(markers: [
                    Marker(point: LatLng(pickupLat, pickupLng), child: const Icon(Icons.radio_button_on_rounded, color: AppColors.primary, size: 32)),
                    Marker(point: LatLng(destLat, destLng), child: const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 32)),
                  ]),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_errand!['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(_errand!['description'] ?? '', style: const TextStyle(color: AppColors.runnerTextMuted, fontSize: 14)),
                    const SizedBox(height: 16),

                    // Customer
                    if (customer != null) Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.runnerSurface, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const CircleAvatar(backgroundColor: AppColors.primary, radius: 20, child: Icon(Icons.person, color: Colors.white, size: 22)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              const Text('Customer', style: TextStyle(color: AppColors.runnerTextMuted, fontSize: 12)),
                            ],
                          )),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.phone_outlined, color: AppColors.primary)),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Locations
                    _locationRow(Icons.radio_button_on_rounded, AppColors.primary, 'Pickup', _errand!['pickup_address'] ?? ''),
                    const SizedBox(height: 8),
                    _locationRow(Icons.location_on_rounded, AppColors.danger, 'Destination', _errand!['destination_address'] ?? ''),

                    const SizedBox(height: 20),

                    // Earnings
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Text('₦${_errand!['runner_earnings'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (['accepted', 'runner_en_route', 'item_picked'].contains(status))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _cancelErrand,
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                            child: const Text('Cancel errand', style: TextStyle(color: AppColors.danger)),
                          ),
                        ),
                      ),

                    // Action buttons based on status
                    ..._buildActions(status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(String status) {
    return switch (status) {
      'accepted' => [
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _markArrived,
          icon: const Icon(Icons.directions_run_rounded),
          label: const Text('I Have Arrived at Pickup'),
        )),
      ],
      'runner_en_route' => [
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _verifyPickupOtp,
          icon: const Icon(Icons.pin_outlined),
          label: const Text('Enter Pickup OTP'),
        )),
      ],
      'item_picked' => [
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _startErrand,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Errand'),
        )),
      ],
      'in_progress' => [
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _submitProof,
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Submit Proof & Mark Complete'),
        )),
      ],
      'awaiting_confirmation' => [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryFaded, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            children: [
              Icon(Icons.hourglass_empty_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Waiting for customer to confirm delivery', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      _ => [],
    };
  }

  Widget _locationRow(IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.runnerTextMuted, fontSize: 12)),
              Text(address, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
