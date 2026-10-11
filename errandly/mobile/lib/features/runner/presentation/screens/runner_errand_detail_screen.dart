import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/network/api_client.dart';
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

  Future<void> _verifyPickupOtp(ColorScheme colorScheme) async {
    final otp = await _showOtpDialog('Enter Pickup OTP', colorScheme);
    if (otp == null || otp.length != 6) return;
    try {
      final api = getIt<ApiClient>();
      await api.verifyPickupOtp(widget.errandPublicId, otp);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Pickup verified! You can now start the errand.'), backgroundColor: Colors.green.shade600),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Invalid OTP.'), backgroundColor: colorScheme.error),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit Proof', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
            const SizedBox(height: 24),
            _ProofOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Upload Photo Proof',
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
              icon: Icons.receipt_rounded,
              title: 'Upload Receipt',
              colorScheme: colorScheme,
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

  Future<void> _cancelErrand(ColorScheme colorScheme) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cancel errand?', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        content: TextField(
          controller: reason, 
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Reason',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No', style: TextStyle(color: colorScheme.onSurfaceVariant))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Yes, cancel', style: TextStyle(fontWeight: FontWeight.w700)),
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
          SnackBar(content: const Text('Could not cancel'), backgroundColor: colorScheme.error),
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
          SnackBar(content: const Text('Panic alert sent. Admin has been notified.'), backgroundColor: colorScheme.error),
        );
        _load();
      }
    } catch (e) {}
  }

  Future<String?> _showOtpDialog(String title, ColorScheme colorScheme) async {
    String otp = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        content: PinCodeTextField(
          appContext: context,
          length: 6,
          onChanged: (v) => otp = v,
          textStyle: TextStyle(color: colorScheme.onSurface),
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            activeColor: colorScheme.primary,
            selectedColor: colorScheme.primary,
            inactiveColor: colorScheme.outlineVariant,
            activeFillColor: colorScheme.surfaceVariant,
            selectedFillColor: colorScheme.surfaceVariant,
            inactiveFillColor: colorScheme.surfaceVariant.withOpacity(0.5),
          ),
          enableActiveFill: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, otp), 
            child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    if (_errand == null) return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: Center(child: Text('Not found', style: TextStyle(color: colorScheme.onSurface))));

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
        title: Text(statusLabel, style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: colorScheme.errorContainer.withOpacity(0.8), shape: BoxShape.circle),
            child: IconButton(
              onPressed: () => _triggerPanic(colorScheme),
              icon: Icon(Icons.emergency_rounded, color: colorScheme.error),
              tooltip: 'Panic',
            ),
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
                  Marker(point: LatLng(pickupLat, pickupLng), child: Icon(Icons.radio_button_on_rounded, color: colorScheme.primary, size: 40)),
                  Marker(point: LatLng(destLat, destLng), child: Icon(Icons.location_on_rounded, color: colorScheme.error, size: 40)),
                ]),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_errand!['title'] ?? '', style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  Text(_errand!['description'] ?? '', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15)),
                  const SizedBox(height: 24),

                  // Customer
                  if (customer != null) Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.outlineVariant)),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: colorScheme.primary.withOpacity(0.2), radius: 24, child: Icon(Icons.person, color: colorScheme.primary, size: 28)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer['full_name'] ?? '', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Customer', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        )),
                        Container(
                          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                          child: IconButton(onPressed: () {}, icon: Icon(Icons.phone_outlined, color: colorScheme.primary)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                          child: IconButton(onPressed: () {}, icon: Icon(Icons.chat_bubble_outline_rounded, color: colorScheme.onPrimary)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Locations
                  _LocationRow(icon: Icons.radio_button_on_rounded, color: colorScheme.primary, label: 'Pickup', address: _errand!['pickup_address'] ?? '', colorScheme: colorScheme),
                  const SizedBox(height: 16),
                  _LocationRow(icon: Icons.location_on_rounded, color: colorScheme.error, label: 'Destination', address: _errand!['destination_address'] ?? '', colorScheme: colorScheme),

                  const SizedBox(height: 32),

                  // Earnings
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your Earnings', style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('₦${_errand!['runner_earnings'] ?? 0}', style: TextStyle(color: colorScheme.onPrimary, fontSize: 32, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (['accepted', 'runner_en_route', 'item_picked'].contains(status))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => _cancelErrand(colorScheme),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorScheme.error, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Cancel errand', style: TextStyle(color: colorScheme.error, fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),

                  // Action buttons based on status
                  ..._buildActions(status, colorScheme),
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
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(
          onPressed: _markArrived,
          icon: const Icon(Icons.directions_run_rounded),
          label: const Text('I Have Arrived at Pickup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
      ],
      'runner_en_route' => [
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(
          onPressed: () => _verifyPickupOtp(colorScheme),
          icon: const Icon(Icons.pin_outlined),
          label: const Text('Enter Pickup OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
      ],
      'item_picked' => [
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(
          onPressed: _startErrand,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Errand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
      ],
      'in_progress' => [
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(
          onPressed: () => _submitProof(colorScheme),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Submit Proof & Mark Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
      ],
      'awaiting_confirmation' => [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty_rounded, color: colorScheme.onPrimaryContainer, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Text('Waiting for customer to confirm delivery', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 15))),
            ],
          ),
        ),
      ],
      _ => [],
    };
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;
  final ColorScheme colorScheme;

  const _LocationRow({required this.icon, required this.color, required this.label, required this.address, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(address, style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProofOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ProofOptionTile({required this.icon, required this.title, required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurfaceVariant, size: 16),
          ],
        ),
      ),
    );
  }
}
