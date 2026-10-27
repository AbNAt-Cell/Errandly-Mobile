import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/audio_alert_service.dart';
import '../../../../main.dart';
import 'customer_message_thread_screen.dart';
import '../../../shared/presentation/screens/voice_call_screen.dart';

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
  bool _verifyingPayment = false;
  String? _subscribedErrandId;
  void Function(String, dynamic)? _realtimeListener;
  List<Map<String, dynamic>> _activeGateways = [];

  Future<void> _payWithGateway(String gateway) async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.initializeErrandPayment(widget.errandPublicId, gateway: gateway);
      final paymentData = res.data['payment'];
      if (paymentData != null) {
        final authUrl = (paymentData['authorization_url'] ?? paymentData['checkout_url'] ?? paymentData['payment_url'])?.toString();
        if (authUrl != null && authUrl.isNotEmpty) {
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (mounted) {
              final gwLabel = gateway == 'bach' ? 'Bachs' : 'Paystack';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening $gwLabel checkout. Return here and tap "Verify" when completed.'),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not initialize checkout: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showPaymentGatewaySheet(ColorScheme colorScheme) {
    final availableGateways = _activeGateways.isNotEmpty
        ? _activeGateways
        : [
            {'id': 'paystack', 'name': 'Paystack', 'title': 'Paystack', 'tagline': 'Cards, Bank Transfer, Apple Pay, USSD'},
            {'id': 'bach', 'name': 'Bachs', 'title': 'Bachs Pay', 'tagline': 'Fast Checkout, Virtual Account, Cards & Seamless Pay'},
          ];

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Select your preferred gateway to complete escrow funding.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ...availableGateways.map((gw) {
              final id = (gw['id'] ?? '').toString();
              final title = (gw['title'] ?? gw['name'] ?? id).toString();
              final tagline = (gw['tagline'] ?? gw['description'] ?? 'Instant Checkout').toString();
              final isBach = id == 'bach';
              final isPaystack = id == 'paystack';
              final assetIcon = isBach ? 'assets/icons/bach.png' : (isPaystack ? 'assets/icons/paystack.png' : null);
              final icon = isBach ? Icons.flash_on_rounded : Icons.credit_card_rounded;
              final gwColor = isBach ? const Color(0xFF10B981) : (isPaystack ? const Color(0xFF09A5DB) : AppColors.primary);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    _payWithGateway(id);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isBach ? Colors.black : gwColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: assetIcon != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(assetIcon, fit: BoxFit.contain),
                          )
                        : Icon(icon, color: gwColor),
                  ),
                  title: Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      if (isBach || gw['badge'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gwColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isBach ? 'FAST' : gw['badge'].toString(),
                            style: TextStyle(color: gwColor, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(tagline, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyPayment() async {
    setState(() => _verifyingPayment = true);
    try {
      final api = getIt<ApiClient>();
      final res = await api.verifyErrandPayment(widget.errandPublicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Payment verified successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _verifyingPayment = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _startTrackingPoll();
  }

  void _setupRealtimeSubscription(String errandId) {
    if (_subscribedErrandId == errandId) return;
    _cleanupRealtime();
    _subscribedErrandId = errandId;
    _realtimeListener = (event, data) {
      if (!mounted) return;
      if (event == 'RunnerAssigned' || (data is Map && data['status'] == 'accepted')) {
        AudioAlertService.instance.playCustomerChime();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🎉 A runner has accepted your errand!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      } else if (event == 'RunnerLocationUpdated' && data is Map) {
        setState(() {
          _tracking = data as Map<String, dynamic>;
        });
      } else if (event == 'ErrandStatusUpdated') {
        _load();
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

  void _startTrackingPoll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 15));
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

      try {
        final gwRes = await api.getPaymentGateways();
        final gwData = gwRes.data;
        if (gwData is Map && gwData['gateways'] is List) {
          _activeGateways = (gwData['gateways'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {}

      setState(() {
        _errand = errandRes.data;
        _loading = false;
      });

      if (_errand != null && _errand!['id'] != null) {
        _setupRealtimeSubscription(_errand!['id'].toString());
      }

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
          const SnackBar(
            content: Text('Errand confirmed! Payment released to runner.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid OTP. Please check with your runner and try again.'),
            backgroundColor: colorScheme.error,
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        title: Text(
          'Enter Delivery OTP',
          style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.3),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-digit confirmation code provided upon delivery to release funds to the runner.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
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
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, otp),
            child: const Text('Confirm & Release', style: TextStyle(fontWeight: FontWeight.w800)),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          title: Text(
            'Rate Your Runner',
            style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.3),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help build a trusted community by rating your experience.',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => score = starIndex),
                    icon: Icon(
                      starIndex <= score ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: comment,
                maxLines: 3,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Share details of your experience (optional)',
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
              child: Text('Skip', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.w800)),
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
          const SnackBar(content: Text('Rating submitted. Thank you!'), backgroundColor: Color(0xFF10B981)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.gavel_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            Text('Raise Dispute', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select the reason for your dispute:', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: type,
              builder: (_, v, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: v,
                    isExpanded: true,
                    dropdownColor: colorScheme.surface,
                    items: const [
                      DropdownMenuItem(value: 'item_not_delivered', child: Text('Item Not Delivered')),
                      DropdownMenuItem(value: 'item_damaged', child: Text('Item Damaged')),
                      DropdownMenuItem(value: 'runner_unresponsive', child: Text('Runner Unresponsive')),
                      DropdownMenuItem(value: 'other', child: Text('Other Issue')),
                    ],
                    onChanged: (x) => type.value = x ?? v,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: desc,
              maxLines: 3,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Describe what happened in detail...',
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
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Dispute', style: TextStyle(fontWeight: FontWeight.w800)),
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
          const SnackBar(content: Text('Dispute submitted. Admin will investigate promptly.'), backgroundColor: Color(0xFF10B981)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 12),
            Text('Panic Alert', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'This will immediately alert our emergency response team, freeze the transaction, and notify support. Use only in a genuine emergency.',
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Panic Alert', style: TextStyle(fontWeight: FontWeight.w800)),
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
          const SnackBar(
            content: Text('Emergency alert sent! Support team has been dispatched.'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to send panic alert. Call emergency directly.'), backgroundColor: colorScheme.error),
        );
      }
    }
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
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Home')),
            ],
          ),
        ),
      );
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
          // App Bar with Map View
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (runner != null)
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
                            contactName: runner['full_name'] ?? 'Runner',
                            contactAvatar: runner['avatar_url'] as String?,
                            isIncoming: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 20),
                    tooltip: 'In-App Voice Call',
                  ),
                ),
              if (isActive)
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
                    tooltip: 'Emergency Panic Alert',
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMap(runnerLocation, colorScheme, isActive),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Public ID row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusBg(status),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: _statusBorder(status)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _statusColor(status, colorScheme),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusLabel.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(status, colorScheme),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.errandPublicId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Errand ID copied to clipboard'), duration: Duration(seconds: 1)),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#${widget.errandPublicId.length > 8 ? widget.errandPublicId.substring(0, 8) : widget.errandPublicId}',
                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.copy_rounded, color: colorScheme.onSurfaceVariant, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title & Description
                  Text(
                    _errand!['title'] ?? '',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5, height: 1.25),
                  ),
                  if ((_errand!['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errand!['description'] ?? '',
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.45),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Errand Lifecycle Progress Bar
                  _ErrandProgressTracker(status: status, colorScheme: colorScheme),

                  const SizedBox(height: 24),

                  // Locations Timeline Card
                  _TimelineLocationsCard(
                    pickup: _errand!['pickup_address'] ?? 'Pickup location not specified',
                    destination: _errand!['destination_address'] ?? 'Destination not specified',
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: 24),

                  // Runner Card (if assigned)
                  if (runner != null) ...[
                    Row(
                      children: [
                        Text('Assigned Runner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: const Text('KYC VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _RunnerCard(
                      runner: runner,
                      colorScheme: colorScheme,
                      errandPublicId: widget.errandPublicId,
                      errandTitle: _errand!['title'] ?? 'Errand',
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Payment & Escrow Card
                  _PaymentCard(
                    errand: _errand!,
                    colorScheme: colorScheme,
                    onPayNow: () => _showPaymentGatewaySheet(colorScheme),
                    onVerify: _verifyPayment,
                    verifying: _verifyingPayment,
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  if (canConfirm)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmCompletion(colorScheme),
                        icon: const Icon(Icons.check_circle_rounded, size: 22),
                        label: const Text('Confirm Delivery & Release Escrow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                  if (status == 'completed') ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _rateRunner(colorScheme),
                        icon: const Icon(Icons.star_rounded, size: 22, color: Color(0xFFF59E0B)),
                        label: const Text('Rate Your Runner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurface,
                          elevation: 0,
                          side: BorderSide(color: colorScheme.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  if (['completed', 'awaiting_confirmation', 'in_progress', 'disputed'].contains(status)) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => _openDispute(colorScheme),
                        icon: Icon(Icons.gavel_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                        label: Text('Need Help? Raise a Dispute', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
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

  Widget _buildMap(Map<String, dynamic>? runnerLocation, ColorScheme colorScheme, bool isActive) {
    final pickupLat = (_errand?['pickup_latitude'] as num?)?.toDouble() ?? AppConstants.defaultLat;
    final pickupLng = (_errand?['pickup_longitude'] as num?)?.toDouble() ?? AppConstants.defaultLng;
    final runnerLat = (runnerLocation?['latitude'] as num?)?.toDouble() ?? pickupLat;
    final runnerLng = (runnerLocation?['longitude'] as num?)?.toDouble() ?? pickupLng;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: LatLng(runnerLat, runnerLng), initialZoom: 14),
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
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                ),
              ),
              if (runnerLocation != null)
                Marker(
                  point: LatLng(runnerLat, runnerLng),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 24),
                  ),
                ),
            ]),
          ],
        ),
        // Live GPS banner overlay
        if (isActive)
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      runnerLocation != null ? 'Live GPS Active • Tracking Runner' : 'Runner En Route • Connecting GPS',
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    return switch (status) {
      'completed' => const Color(0xFF10B981),
      'cancelled' || 'failed' => const Color(0xFFEF4444),
      'disputed' => const Color(0xFFF59E0B),
      'awaiting_confirmation' => const Color(0xFF3B82F6),
      _ => colorScheme.primary,
    };
  }

  Color _statusBg(String status) {
    return switch (status) {
      'completed' => const Color(0xFF10B981).withValues(alpha: 0.12),
      'cancelled' || 'failed' => const Color(0xFFEF4444).withValues(alpha: 0.12),
      'disputed' => const Color(0xFFF59E0B).withValues(alpha: 0.12),
      'awaiting_confirmation' => const Color(0xFF3B82F6).withValues(alpha: 0.12),
      _ => AppColors.primary.withValues(alpha: 0.12),
    };
  }

  Color _statusBorder(String status) {
    return switch (status) {
      'completed' => const Color(0xFF10B981).withValues(alpha: 0.3),
      'cancelled' || 'failed' => const Color(0xFFEF4444).withValues(alpha: 0.3),
      'disputed' => const Color(0xFFF59E0B).withValues(alpha: 0.3),
      'awaiting_confirmation' => const Color(0xFF3B82F6).withValues(alpha: 0.3),
      _ => AppColors.primary.withValues(alpha: 0.3),
    };
  }
}

class _ErrandProgressTracker extends StatelessWidget {
  final String status;
  final ColorScheme colorScheme;
  const _ErrandProgressTracker({required this.status, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'key': 'pending', 'label': 'Requested'},
      {'key': 'accepted', 'label': 'Matched'},
      {'key': 'runner_en_route', 'label': 'En Route'},
      {'key': 'in_progress', 'label': 'In Transit'},
      {'key': 'completed', 'label': 'Delivered'},
    ];

    int currentIdx = 0;
    if (status == 'accepted') currentIdx = 1;
    if (status == 'runner_en_route') currentIdx = 2;
    if (['item_picked', 'in_progress', 'awaiting_confirmation'].contains(status)) currentIdx = 3;
    if (status == 'completed') currentIdx = 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colorScheme.onSurfaceVariant)),
              Text('Step ${currentIdx + 1} of 5', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(stages.length, (i) {
              final isDone = i <= currentIdx;
              final isCurrent = i == currentIdx;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDone ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isCurrent ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.4), blurRadius: 4)] : null,
                        ),
                      ),
                    ),
                    if (i < stages.length - 1) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stages[0]['label']!, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              Text(stages[currentIdx]['label']!, style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w800)),
              Text(stages.last['label']!, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
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

class _RunnerCard extends StatelessWidget {
  final Map<String, dynamic> runner;
  final ColorScheme colorScheme;
  final String errandPublicId;
  final String errandTitle;
  const _RunnerCard({
    required this.runner,
    required this.colorScheme,
    required this.errandPublicId,
    required this.errandTitle,
  });

  @override
  Widget build(BuildContext context) {
    final profile = runner['runner_profile'];
    final name = runner['full_name'] ?? 'Errand Runner';
    final phone = runner['phone'] as String?;
    final rating = (profile?['average_rating'] ?? 5.0).toDouble();
    final trustScore = (profile?['trust_score'] ?? 85).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              radius: 24,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'R',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colorScheme.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: BoxDecoration(color: colorScheme.outlineVariant, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Trust: $trustScore', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: IconButton(
                onPressed: () => UrlHelper.open(context, 'tel:$phone'),
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
                      errandId: errandPublicId,
                      errandTitle: errandTitle,
                      contactName: name,
                      contactAvatar: runner['avatar_url'] as String?,
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
                    builder: (_) => CustomerMessageThreadScreen(publicId: errandPublicId),
                  ),
                );
              },
              icon: Icon(Icons.chat_bubble_rounded, color: colorScheme.onPrimary, size: 20),
              tooltip: 'Chat with Runner',
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
  final VoidCallback? onPayNow;
  final VoidCallback? onVerify;
  final bool verifying;

  const _PaymentCard({
    required this.errand,
    required this.colorScheme,
    this.onPayNow,
    this.onVerify,
    this.verifying = false,
  });

  @override
  Widget build(BuildContext context) {
    final budget = errand['budget'] ?? 0;
    final fee = errand['platform_fee'] ?? 0;
    final total = budget + fee;
    final paymentStatus = (errand['payment_status'] ?? '').toString();
    final isPending = paymentStatus == 'pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? const Color(0xFFF59E0B) : colorScheme.outlineVariant,
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPending ? Icons.pending_actions_rounded : Icons.shield_rounded,
                      color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPending ? 'PAYMENT PENDING' : 'ESCROW SECURED',
                      style: TextStyle(
                        color: isPending ? const Color(0xFFD97706) : const Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow('Runner Fee', '₦$budget', colorScheme),
          const SizedBox(height: 10),
          _buildRow('Platform Fee (15%)', '₦$fee', colorScheme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: colorScheme.outlineVariant),
          ),
          _buildRow('Total Escrow Deposit', '₦$total', colorScheme, bold: true, color: isPending ? const Color(0xFFD97706) : colorScheme.primary),
          const SizedBox(height: 16),
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Payment Required to Dispatch',
                        style: TextStyle(color: Color(0xFFD97706), fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete checkout via Paystack or Bachs so this errand can be broadcast to nearby runners.',
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onPayNow,
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: const Text('Pay Escrow', style: TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: verifying ? null : onVerify,
                        icon: verifying
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Verify', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Funds are held securely by Errand and released only after your confirmation.',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, ColorScheme colorScheme, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: bold ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            color: color ?? colorScheme.onSurface,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
