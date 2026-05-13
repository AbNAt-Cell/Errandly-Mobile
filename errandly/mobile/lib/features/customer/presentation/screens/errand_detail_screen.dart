import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../main.dart';

class ErrandDetailScreen extends StatefulWidget {
  final int errandId;
  const ErrandDetailScreen({super.key, required this.errandId});

  @override
  State<ErrandDetailScreen> createState() => _ErrandDetailScreenState();
}

class _ErrandDetailScreenState extends State<ErrandDetailScreen> {
  Map<String, dynamic>? _errand;
  Map<String, dynamic>? _tracking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final errandRes = await api.getErrand(widget.errandId);
      setState(() {
        _errand = errandRes.data;
        _loading = false;
      });

      if (_errand != null && _errand!['runner_id'] != null) {
        final trackRes = await api.trackErrand(widget.errandId);
        setState(() => _tracking = trackRes.data);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmCompletion() async {
    final otp = await _showOtpDialog();
    if (otp == null || otp.length != 6) return;

    try {
      final api = getIt<ApiClient>();
      await api.confirmCompletion(widget.errandId, otp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errand confirmed! Payment released to runner.'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<String?> _showOtpDialog() async {
    String otp = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enter Delivery OTP', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-digit OTP sent to your phone to confirm delivery.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            PinCodeTextField(
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, otp), child: const Text('Confirm')),
        ],
      ),
    );
  }

  Future<void> _triggerPanic() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Panic Alert', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
        content: const Text('This will immediately alert our admin team and freeze the transaction. Use only in an emergency.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Panic Alert'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = getIt<ApiClient>();
      await api.triggerPanic(widget.errandId, {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panic alert sent. Admin is on the way.'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_errand == null) {
      return const Scaffold(body: Center(child: Text('Errand not found')));
    }

    final status = _errand!['status'] ?? '';
    final statusLabel = AppConstants.statusLabels[status] ?? status;
    final runner = _errand!['runner'];
    final runnerLocation = _tracking?['runner_location'];
    final isActive = ['accepted', 'runner_en_route', 'item_picked', 'in_progress', 'awaiting_confirmation'].contains(status);
    final canConfirm = status == 'awaiting_confirmation';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: AppColors.navy,
            actions: [
              if (isActive)
                IconButton(
                  onPressed: _triggerPanic,
                  icon: const Icon(Icons.emergency_rounded, color: Colors.red),
                  tooltip: 'Panic Alert',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMap(runnerLocation),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(_errand!['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(_errand!['description'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Locations
                  _LocationRow(icon: Icons.radio_button_on_rounded, color: AppColors.primary, label: 'Pickup', address: _errand!['pickup_address'] ?? ''),
                  const SizedBox(height: 12),
                  _LocationRow(icon: Icons.location_on_rounded, color: AppColors.danger, label: 'Destination', address: _errand!['destination_address'] ?? ''),

                  const SizedBox(height: 20),

                  // Runner card
                  if (runner != null) ...[
                    const Text('Your Runner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _RunnerCard(runner: runner),
                  ],

                  const SizedBox(height: 20),

                  // Payment
                  _PaymentCard(errand: _errand!),

                  const SizedBox(height: 24),

                  // Actions
                  if (canConfirm)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmCompletion,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Confirm Completion'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      ),
                    ),

                  if (isActive) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _triggerPanic,
                        icon: const Icon(Icons.emergency_rounded, color: AppColors.danger),
                        label: const Text('Panic Button', style: TextStyle(color: AppColors.danger)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(Map<String, dynamic>? runnerLocation) {
    final pickupLat = (_errand?['pickup_latitude'] as num?)?.toDouble() ?? AppConstants.defaultLat;
    final pickupLng = (_errand?['pickup_longitude'] as num?)?.toDouble() ?? AppConstants.defaultLng;
    final runnerLat = (runnerLocation?['latitude'] as num?)?.toDouble() ?? pickupLat;
    final runnerLng = (runnerLocation?['longitude'] as num?)?.toDouble() ?? pickupLng;

    return FlutterMap(
      options: MapOptions(initialCenter: LatLng(runnerLat, runnerLng), initialZoom: 14),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
        MarkerLayer(markers: [
          Marker(
            point: LatLng(pickupLat, pickupLng),
            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 36),
          ),
          if (runnerLocation != null)
            Marker(
              point: LatLng(runnerLat, runnerLng),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 20),
              ),
            ),
        ]),
      ],
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'completed' => AppColors.success,
      'cancelled' || 'failed' => AppColors.danger,
      'disputed' => AppColors.warning,
      _ => AppColors.primary,
    };
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _LocationRow({required this.icon, required this.color, required this.label, required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              Text(address, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunnerCard extends StatelessWidget {
  final Map<String, dynamic> runner;
  const _RunnerCard({required this.runner});

  @override
  Widget build(BuildContext context) {
    final profile = runner['runner_profile'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: AppColors.primary, radius: 24, child: Icon(Icons.person, color: Colors.white, size: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(runner['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 2),
                    Text('${(profile?['average_rating'] ?? 0.0).toStringAsFixed(1)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Text('Trust: ${(profile?['trust_score'] ?? 70).toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> errand;
  const _PaymentCard({required this.errand});

  @override
  Widget build(BuildContext context) {
    final budget = errand['budget'] ?? 0;
    final fee = errand['platform_fee'] ?? 0;
    final total = budget + fee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          _Row('Runner payment', '₦$budget'),
          const SizedBox(height: 4),
          _Row('Platform fee (15%)', '₦$fee'),
          const Divider(height: 16),
          _Row('Total', '₦$total', bold: true, color: AppColors.primary),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.success, size: 14),
                const SizedBox(width: 4),
                Text(
                  errand['payment_status'] == 'in_escrow' ? 'Held securely in escrow' : (errand['payment_status'] ?? ''),
                  style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _Row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 14, color: color ?? AppColors.textPrimary, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
      ],
    );
  }
}
