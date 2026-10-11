import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../main.dart';

class ErrandDetailScreen extends StatefulWidget {
  final String errandPublicId;
  const ErrandDetailScreen({super.key, required this.errandPublicId});

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
    _startTrackingPoll();
  }

  void _startTrackingPoll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 12));
      if (!mounted || _errand == null || _errand!['runner_id'] == null) return false;
      try {
        final trackRes = await getIt<ApiClient>().trackErrand(widget.errandPublicId);
        if (mounted) setState(() => _tracking = trackRes.data);
      } catch (_) {}
      return mounted;
    });
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final errandRes = await api.getErrand(widget.errandPublicId);
      setState(() {
        _errand = errandRes.data;
        _loading = false;
      });

      if (_errand != null && _errand!['runner_id'] != null) {
        final trackRes = await api.trackErrand(widget.errandPublicId);
        setState(() => _tracking = trackRes.data);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmCompletion(ColorScheme colorScheme) async {
    final otp = await _showOtpDialog(colorScheme);
    if (otp == null || otp.length != 6) return;

    try {
      final api = getIt<ApiClient>();
      await api.confirmCompletion(widget.errandPublicId, otp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Errand confirmed! Payment released to runner.'), backgroundColor: Colors.green.shade600),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Invalid OTP. Please try again.'), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  Future<String?> _showOtpDialog(ColorScheme colorScheme) async {
    String otp = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Enter Delivery OTP', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the 6-digit OTP sent to your phone to confirm delivery.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 24),
            PinCodeTextField(
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
          ],
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
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _rateRunner(ColorScheme colorScheme) async {
    int score = 5;
    final comment = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Rate runner', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: score,
                isExpanded: true,
                dropdownColor: colorScheme.surfaceVariant,
                items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} stars', style: TextStyle(color: colorScheme.onSurface)))),
                onChanged: (v) => setState(() => score = v ?? 5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: comment, 
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Comment (optional)',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                )
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Skip', style: TextStyle(color: colorScheme.onSurfaceVariant))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await getIt<ApiClient>().submitRating({
        'public_id': widget.errandPublicId,
        'overall_rating': score,
        'communication': score,
        'comment': comment.text.trim().isEmpty ? null : comment.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Rating submitted'), backgroundColor: Colors.green.shade600),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Could not submit rating'), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  Future<void> _openDispute(ColorScheme colorScheme) async {
    final type = ValueNotifier<String>('item_not_delivered');
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Raise dispute', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder(
              valueListenable: type,
              builder: (_, v, __) => DropdownButton<String>(
                value: v,
                isExpanded: true,
                dropdownColor: colorScheme.surfaceVariant,
                items: [
                  DropdownMenuItem(value: 'item_not_delivered', child: Text('Not delivered', style: TextStyle(color: colorScheme.onSurface))),
                  DropdownMenuItem(value: 'item_damaged', child: Text('Damaged', style: TextStyle(color: colorScheme.onSurface))),
                  DropdownMenuItem(value: 'other', child: Text('Other', style: TextStyle(color: colorScheme.onSurface))),
                ],
                onChanged: (x) => type.value = x ?? v,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: desc, 
              maxLines: 3, 
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Describe the issue',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || desc.text.trim().isEmpty) return;
    try {
      await getIt<ApiClient>().openDispute({
        'public_id': widget.errandPublicId,
        'type': type.value,
        'description': desc.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Dispute submitted'), backgroundColor: Colors.green.shade600),
        );
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Could not open dispute'), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  Future<void> _triggerPanic(ColorScheme colorScheme) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Panic Alert', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w800)),
        content: Text('This will immediately alert our admin team and freeze the transaction. Use only in an emergency.', style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Panic Alert', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = getIt<ApiClient>();
      await api.triggerPanic(widget.errandPublicId, {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Panic alert sent. Admin is on the way.'), backgroundColor: colorScheme.error),
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    if (_errand == null) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: Center(child: Text('Errand not found', style: TextStyle(color: colorScheme.onSurface))));
    }

    final status = _errand!['status'] ?? '';
    final statusLabel = AppConstants.statusLabels[status] ?? status;
    final runner = _errand!['runner'];
    final runnerLocation = _tracking?['runner_location'];
    final isActive = ['accepted', 'runner_en_route', 'item_picked', 'in_progress', 'awaiting_confirmation'].contains(status);
    final canConfirm = status == 'awaiting_confirmation';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: colorScheme.errorContainer.withOpacity(0.8), shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () => _triggerPanic(colorScheme),
                    icon: Icon(Icons.emergency_rounded, color: colorScheme.error),
                    tooltip: 'Panic Alert',
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMap(runnerLocation, colorScheme),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: colorScheme.surface.withOpacity(0.8), shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusColor(status, colorScheme).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(statusLabel, style: TextStyle(color: _statusColor(status, colorScheme), fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(_errand!['title'] ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text(_errand!['description'] ?? '', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),

                  const SizedBox(height: 24),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  const SizedBox(height: 24),

                  // Locations
                  _LocationRow(icon: Icons.radio_button_on_rounded, color: colorScheme.primary, label: 'Pickup', address: _errand!['pickup_address'] ?? '', colorScheme: colorScheme),
                  const SizedBox(height: 16),
                  _LocationRow(icon: Icons.location_on_rounded, color: colorScheme.error, label: 'Destination', address: _errand!['destination_address'] ?? '', colorScheme: colorScheme),

                  const SizedBox(height: 32),

                  // Runner card
                  if (runner != null) ...[
                    Text('Your Runner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    _RunnerCard(runner: runner, colorScheme: colorScheme),
                    const SizedBox(height: 32),
                  ],

                  // Payment
                  _PaymentCard(errand: _errand!, colorScheme: colorScheme),

                  const SizedBox(height: 32),

                  // Actions
                  if (canConfirm)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmCompletion(colorScheme),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Confirm Completion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                  if (isActive) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _triggerPanic(colorScheme),
                        icon: Icon(Icons.emergency_rounded, color: colorScheme.error),
                        label: Text('Panic Button', style: TextStyle(color: colorScheme.error, fontSize: 16, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.error.withOpacity(0.5), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  if (['completed', 'awaiting_confirmation', 'in_progress', 'disputed'].contains(status)) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openDispute(colorScheme),
                        icon: Icon(Icons.gavel_rounded, color: colorScheme.onSurface),
                        label: Text('Raise dispute', style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.outlineVariant),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  if (status == 'completed') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _rateRunner(colorScheme),
                        icon: const Icon(Icons.star_rounded),
                        label: const Text('Rate runner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
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

  Widget _buildMap(Map<String, dynamic>? runnerLocation, ColorScheme colorScheme) {
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
            child: Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 40),
          ),
          if (runnerLocation != null)
            Marker(
              point: LatLng(runnerLat, runnerLng),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.green.shade600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))]),
                child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 22),
              ),
            ),
        ]),
      ],
    );
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    return switch (status) {
      'completed' => Colors.green.shade600,
      'cancelled' || 'failed' => colorScheme.error,
      'disputed' => Colors.orange,
      _ => colorScheme.primary,
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(address, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunnerCard extends StatelessWidget {
  final Map<String, dynamic> runner;
  final ColorScheme colorScheme;
  const _RunnerCard({required this.runner, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final profile = runner['runner_profile'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: colorScheme.outlineVariant)
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: colorScheme.primary.withOpacity(0.2), radius: 28, child: Icon(Icons.person, color: colorScheme.primary, size: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(runner['full_name'] ?? '', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text('${(profile?['average_rating'] ?? 0.0).toStringAsFixed(1)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text('Trust: ${(profile?['trust_score'] ?? 70).toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.chat_bubble_rounded, color: colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> errand;
  final ColorScheme colorScheme;
  const _PaymentCard({required this.errand, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final budget = errand['budget'] ?? 0;
    final fee = errand['platform_fee'] ?? 0;
    final total = budget + fee;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outlineVariant), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colorScheme.onSurface)),
          const SizedBox(height: 20),
          _Row('Runner payment', '₦$budget', colorScheme),
          const SizedBox(height: 12),
          _Row('Platform fee (15%)', '₦$fee', colorScheme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: colorScheme.outlineVariant),
          ),
          _Row('Total', '₦$total', colorScheme, bold: true, color: colorScheme.primary),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.green.shade600.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errand['payment_status'] == 'in_escrow' ? 'Funds held securely in escrow' : (errand['payment_status'] ?? ''),
                    style: TextStyle(color: Colors.green.shade600, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _Row(String label, String value, ColorScheme colorScheme, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: bold ? colorScheme.onSurface : colorScheme.onSurfaceVariant, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 15, color: color ?? colorScheme.onSurface, fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
      ],
    );
  }
}
