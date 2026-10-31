import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/location_picker_sheet.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../main.dart';
import 'errand_detail_screen.dart';

class CreateErrandScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialWorkflowType;

  const CreateErrandScreen({
    super.key,
    this.initialCategory,
    this.initialWorkflowType,
  });

  @override
  State<CreateErrandScreen> createState() => _CreateErrandScreenState();
}

class _CreateErrandScreenState extends State<CreateErrandScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _loading = false;

  // Step 1 — Task info
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _itemDetailsCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();
  String _category = 'grocery_purchase';
  String _urgency = 'standard';
  DateTime? _scheduledAt;

  // Step 2 — Locations & Workflow Config
  String _workflowType = 'pickup_delivery'; // 'pickup_delivery', 'single_location', 'queue_waiting'
  double? _durationHours;
  final _serviceInstructionsCtrl = TextEditingController();
  final _venueNameCtrl = TextEditingController();
  final List<Map<String, dynamic>> _stops = [];
  bool _isLocatingField = false;

  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  double _pickupLat = AppConstants.defaultLat;
  double _pickupLng = AppConstants.defaultLng;
  double _destLat = AppConstants.defaultLat + 0.01;
  double _destLng = AppConstants.defaultLng + 0.01;
  bool _pickupCoordinatesSet = false;
  bool _destCoordinatesSet = false;

  // Step 3 — Budget & Payment
  int _budget = 2000;
  int get _platformFee => (_budget * 0.15).ceil();
  int get _total => _budget + _platformFee;
  String _paymentMethod = 'paystack';
  int _walletBalance = 0;
  List<Map<String, dynamic>> _activeGateways = [];
  String _defaultGateway = 'paystack';

  final List<String> _stepTitles = ['Task Info', 'Locations', 'Budget', 'Review'];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null &&
        AppConstants.categoryLabels.containsKey(widget.initialCategory)) {
      _category = widget.initialCategory!;
      if (widget.initialWorkflowType != null) {
        _workflowType = widget.initialWorkflowType!;
      } else if (_category == 'queue_standing') {
        _workflowType = 'queue_waiting';
      } else if (_category == 'personal_assistance' || _category == 'domestic_chores') {
        _workflowType = 'single_location';
      } else {
        _workflowType = 'pickup_delivery';
      }
    }
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.getWallet();

      try {
        final gwRes = await api.getPaymentGateways();
        final gwData = gwRes.data;
        if (gwData is Map) {
          final list = gwData['gateways'];
          if (list is List) {
            _activeGateways = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
          if (gwData['default_gateway'] is String && (gwData['default_gateway'] as String).isNotEmpty) {
            _defaultGateway = gwData['default_gateway'];
          }
        }
      } catch (_) {
        _activeGateways = [
          {'id': 'paystack', 'name': 'Paystack', 'title': 'Paystack', 'tagline': 'Cards & Transfer'},
          {'id': 'bach', 'name': 'Bachs', 'title': 'Bachs Pay', 'tagline': 'Fast Checkout'},
        ];
      }

      if (mounted) {
        final bal = res.data != null && res.data['balance'] != null
            ? (res.data['balance'] as num).toInt()
            : 0;

        setState(() {
          _walletBalance = bal;
          final activeIds = _activeGateways.map((g) => g['id'].toString()).toList();
          if (bal >= _total) {
            _paymentMethod = 'wallet';
          } else if (activeIds.contains(_defaultGateway)) {
            _paymentMethod = _defaultGateway;
          } else if (activeIds.isNotEmpty) {
            _paymentMethod = activeIds.first;
          } else {
            _paymentMethod = 'wallet';
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _itemDetailsCtrl.dispose();
    _specialCtrl.dispose();
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitErrand() async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();
      final payload = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'workflow_type': _workflowType,
        'urgency': _urgency,
        'pickup_address': _pickupCtrl.text.trim(),
        'pickup_latitude': _pickupLat,
        'pickup_longitude': _pickupLng,
        'recipient_name': _recipientNameCtrl.text.trim(),
        'recipient_phone': _recipientPhoneCtrl.text.trim(),
        'item_details': _itemDetailsCtrl.text.trim(),
        'special_instructions': _specialCtrl.text.trim(),
        'budget': _budget,
        'payment_method': _paymentMethod,
        'frontend_url': AppConstants.frontendUrl,
      };

      if (_scheduledAt != null) {
        payload['scheduled_at'] = _scheduledAt!.toIso8601String();
      }

      if (_workflowType == 'pickup_delivery') {
        payload['destination_address'] = _destCtrl.text.trim();
        payload['destination_latitude'] = _destLat;
        payload['destination_longitude'] = _destLng;
        if (_stops.isNotEmpty) {
          payload['stops'] = _stops;
        }
      }

      if (_durationHours != null) {
        payload['duration_hours'] = _durationHours;
      }
      final extraInstructions = <String>[];
      if (_venueNameCtrl.text.trim().isNotEmpty) {
        extraInstructions.add('Venue / Desk: ${_venueNameCtrl.text.trim()}');
      }
      if (_serviceInstructionsCtrl.text.trim().isNotEmpty) {
        extraInstructions.add(_serviceInstructionsCtrl.text.trim());
      }
      if (extraInstructions.isNotEmpty) {
        payload['service_instructions'] = extraInstructions.join('\n');
      }

      final response = await api.createErrand(payload);

      if (mounted) {
        final errandData = response.data['errand'] ?? {};
        final publicId = errandData['public_id'] as String;
        final paymentData = response.data['payment'];

        if (paymentData != null) {
          final authUrl = (paymentData['authorization_url'] ?? paymentData['checkout_url'] ?? paymentData['payment_url'])?.toString();
          if (authUrl != null && authUrl.isNotEmpty) {
            final uri = Uri.parse(authUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrandDetailScreen(errandPublicId: publicId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.formatErrorMessage(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _stepTitles[_step],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: colorScheme.outlineVariant,
            color: colorScheme.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step indicator dots / pill track
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: colorScheme.surface,
              child: Row(
                children: List.generate(4, (i) {
                  final isActive = i <= _step;
                  final isCurrent = i == _step;
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary
                                : (isActive
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary
                                  : (isActive ? AppColors.primary.withValues(alpha: 0.3) : colorScheme.outlineVariant),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: isActive && !isCurrent
                                ? const Icon(Icons.check_rounded, size: 16, color: AppColors.primary)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: isCurrent
                                          ? Colors.white
                                          : (isActive ? AppColors.primary : colorScheme.onSurfaceVariant),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        if (i < 3)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              color: i < _step ? AppColors.primary : colorScheme.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _buildStep(theme, colorScheme),
              ),
            ),

            // Bottom Navigation Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                if (_step == 0) {
                                  if (_titleCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a task title')),
                                    );
                                    return;
                                  }
                                  if (_descCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please describe what you need the runner to do')),
                                    );
                                    return;
                                  }
                                  setState(() => _step++);
                                } else if (_step == 1) {
                                  if (_pickupCtrl.text.trim().isEmpty || !LocationService.isValidCoordinate(_pickupLat, _pickupLng)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please specify a valid verified location on the map')),
                                    );
                                    return;
                                  }
                                  if (_workflowType == 'pickup_delivery') {
                                    if (_destCtrl.text.trim().isEmpty || !LocationService.isValidCoordinate(_destLat, _destLng)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please specify a valid delivery destination')),
                                      );
                                      return;
                                    }
                                  }
                                  setState(() => _step++);
                                } else if (_step == 2) {
                                  setState(() => _step++);
                                } else {
                                  _submitErrand();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Builder(builder: (_) {
                                    if (_step < 3) {
                                      return const Text(
                                        'Continue',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                      );
                                    }
                                    if (_paymentMethod == 'wallet') {
                                      return Text(
                                        'Pay ₦$_total from Wallet',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                      );
                                    }
                                    final gw = _activeGateways.firstWhere(
                                      (g) => g['id'] == _paymentMethod,
                                      orElse: () => {'title': _paymentMethod == 'bach' ? 'Bachs' : 'Paystack'},
                                    );
                                    final gwName = (gw['title'] ?? gw['name'] ?? _paymentMethod).toString();
                                    return Text(
                                      'Pay Now ₦$_total via $gwName',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                    );
                                  }),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _step < 3
                                        ? Icons.arrow_forward_rounded
                                        : (_paymentMethod == 'wallet'
                                            ? Icons.account_balance_wallet_rounded
                                            : (_paymentMethod == 'bach'
                                                ? Icons.flash_on_rounded
                                                : Icons.credit_card_rounded)),
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, ColorScheme colorScheme) {
    return switch (_step) {
      0 => _buildStep1(theme, colorScheme),
      1 => _buildStep2(theme, colorScheme),
      2 => _buildStep3(theme, colorScheme),
      3 => _buildStep4(theme, colorScheme),
      _ => const SizedBox(),
    };
  }

  Widget _buildStep1(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you need done?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Provide the key details so we can match you with the best runner.',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: 'Task Title',
            hintText: 'e.g. Pick up my medicine from pharmacy',
            prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 18),
        _buildCategoryPicker(colorScheme),
        const SizedBox(height: 18),
        TextFormField(
          controller: _descCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe exactly what you need the runner to do...',
            alignLabelWithHint: true,
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          validator: (v) => ((v?.length ?? 0) < 10) ? 'Describe in more detail' : null,
        ),
        const SizedBox(height: 22),
        Text(
          'Urgency Level',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _urgencyChip('standard', '🕐 Standard', colorScheme),
            _urgencyChip('urgent', '⚡ Urgent', colorScheme),
            _urgencyChip('scheduled', '📅 Scheduled', colorScheme),
          ],
        ),
        if (_urgency == 'scheduled' || _workflowType == 'queue_waiting') ...[
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _pickScheduledDateTime(colorScheme),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _scheduledAt != null
                    ? colorScheme.primary.withValues(alpha: 0.08)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _scheduledAt != null ? colorScheme.primary : colorScheme.outlineVariant,
                  width: _scheduledAt != null ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_available_rounded, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _workflowType == 'queue_waiting'
                              ? 'APPOINTMENT / ARRIVAL TIME'
                              : 'SCHEDULED DATE & TIME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _scheduledAt != null
                              ? DateFormat('EEE, MMM d, yyyy • h:mm a').format(_scheduledAt!)
                              : 'Tap to select appointment date & time...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _scheduledAt != null ? FontWeight.w700 : FontWeight.w500,
                            color: _scheduledAt != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_calendar_rounded, color: colorScheme.primary, size: 20),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        TextFormField(
          controller: _itemDetailsCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Item Details (optional)',
            hintText: 'List items, sizes, quantities, specific brands...',
            prefixIcon: const Icon(Icons.inventory_2_outlined),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _pickLocation({required bool isPickup, required ColorScheme colorScheme}) async {
    final result = await LocationPickerSheet.show(
      context,
      title: isPickup ? 'Pick Exact Pickup Location' : 'Pick Exact Destination Location',
      initialLat: isPickup ? _pickupLat : _destLat,
      initialLng: isPickup ? _pickupLng : _destLng,
      initialAddress: isPickup ? _pickupCtrl.text : _destCtrl.text,
    );

    if (result != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupCtrl.text = result.displayName;
          _pickupLat = result.latitude;
          _pickupLng = result.longitude;
          _pickupCoordinatesSet = true;
        } else {
          _destCtrl.text = result.displayName;
          _destLat = result.latitude;
          _destLng = result.longitude;
          _destCoordinatesSet = true;
        }
      });
    }
  }

  Future<void> _useCurrentLocationForField({required bool isPickup}) async {
    setState(() => _isLocatingField = true);
    final fix = await LocationService.getHighAccuracyPosition();
    if (!mounted) return;
    setState(() => _isLocatingField = false);

    if (!fix.isSuccess || fix.position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fix.message ?? 'Could not acquire GPS position.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final pos = fix.position!;
    final place = await LocationSearchService.reverseGeocode(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        final address = place?.displayName ?? '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        if (isPickup) {
          _pickupCtrl.text = address;
          _pickupLat = pos.latitude;
          _pickupLng = pos.longitude;
          _pickupCoordinatesSet = true;
        } else {
          _destCtrl.text = address;
          _destLat = pos.latitude;
          _destLng = pos.longitude;
          _destCoordinatesSet = true;
        }
      });
      final accMsg = fix.accuracy != null ? ' (±${fix.accuracy!.toStringAsFixed(0)}m)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pinned exact GPS: (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})$accMsg'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addIntermediateStop(ColorScheme colorScheme) async {
    final result = await LocationPickerSheet.show(
      context,
      title: 'Pick Intermediate Stop Location',
      initialLat: _pickupLat,
      initialLng: _pickupLng,
    );
    if (result != null && mounted) {
      setState(() {
        _stops.add({
          'address': result.displayName,
          'latitude': result.latitude,
          'longitude': result.longitude,
          'instructions': '',
        });
      });
    }
  }

  Widget _buildStep2(ThemeData theme, ColorScheme colorScheme) {
    String stepHeading = 'Pickup and Delivery';
    String stepSubtitle = 'Specify exact pickup point, stops, and final destination.';
    if (_workflowType == 'single_location') {
      stepHeading = 'Service Location & Duration';
      stepSubtitle = 'Specify where the runner reports and required service duration.';
    } else if (_workflowType == 'queue_waiting') {
      stepHeading = 'Queue Venue & Instructions';
      stepSubtitle = 'Specify queue venue, target office/booth, and handover rules.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepHeading,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stepSubtitle,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        // Custom errand workflow mode switcher
        if (_category == 'custom_errand') ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _workflowPill('pickup_delivery', 'Delivery', colorScheme),
                _workflowPill('single_location', 'On-Site', colorScheme),
                _workflowPill('queue_waiting', 'Queue', colorScheme),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Primary Location Card (Pickup / Venue / Service Location)
        TextFormField(
          controller: _pickupCtrl,
          decoration: InputDecoration(
            labelText: _workflowType == 'pickup_delivery'
                ? 'Pickup Address'
                : (_workflowType == 'single_location' ? 'Service Location Address' : 'Queue Venue Address'),
            hintText: 'Search or enter location...',
            prefixIcon: Icon(
              _workflowType == 'pickup_delivery'
                  ? Icons.radio_button_checked_rounded
                  : (_workflowType == 'single_location' ? Icons.home_work_rounded : Icons.hourglass_top_rounded),
              color: AppColors.primary,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map_rounded, color: AppColors.primary),
              tooltip: 'Choose on Map',
              onPressed: () => _pickLocation(isPickup: true, colorScheme: colorScheme),
            ),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            InkWell(
              onTap: _isLocatingField ? null : () => _useCurrentLocationForField(isPickup: true),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLocatingField)
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                    else
                      const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('Current Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _pickLocation(isPickup: true, colorScheme: colorScheme),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text('Choose on Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
              ),
            ),
            if (_pickupCoordinatesSet) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                    SizedBox(width: 4),
                    Text('Coordinates Pinned', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ],
        ),

        // Type A: Delivery Workflow (Intermediate Stops + Destination)
        if (_workflowType == 'pickup_delivery') ...[
          const SizedBox(height: 16),
          // Intermediate Stops List
          if (_stops.isNotEmpty) ...[
            Text(
              'Intermediate Stops (${_stops.length})',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            ..._stops.asMap().entries.map((entry) {
              final idx = entry.key;
              final stop = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                      child: Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stop['address'] ?? '',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      onPressed: () => setState(() => _stops.removeAt(idx)),
                      tooltip: 'Remove stop',
                    ),
                  ],
                ),
              );
            }),
          ],
          OutlinedButton.icon(
            onPressed: () => _addIntermediateStop(colorScheme),
            icon: const Icon(Icons.add_location_alt_rounded, size: 16),
            label: const Text('Add Intermediate Stop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Destination Address
          TextFormField(
            controller: _destCtrl,
            decoration: InputDecoration(
              labelText: 'Destination Address',
              hintText: 'Search or enter destination location...',
              prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.danger),
              suffixIcon: IconButton(
                icon: const Icon(Icons.map_rounded, color: AppColors.danger),
                tooltip: 'Choose on Map',
                onPressed: () => _pickLocation(isPickup: false, colorScheme: colorScheme),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            validator: (v) => (_workflowType == 'pickup_delivery' && (v?.isEmpty ?? true)) ? 'Required' : null,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                onTap: _isLocatingField ? null : () => _useCurrentLocationForField(isPickup: false),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded, size: 14, color: AppColors.danger),
                      SizedBox(width: 4),
                      Text('Current Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _pickLocation(isPickup: false, colorScheme: colorScheme),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text('Choose on Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                ),
              ),
              if (_destCoordinatesSet) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                      SizedBox(width: 4),
                      Text('Coordinates Pinned', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],

        // Type B: Single Location Domestic / On-Site Service Fields
        if (_workflowType == 'single_location') ...[
          const SizedBox(height: 20),
          Text(
            'Estimated Service Duration (Hours)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0].map((h) {
              final sel = _durationHours == h;
              final label = h == 0.5 ? '30 mins' : (h % 1 == 0 ? '${h.toInt()} hr${h > 1 ? "s" : ""}' : '$h hrs');
              return ChoiceChip(
                label: Text(label),
                selected: sel,
                onSelected: (val) => setState(() => _durationHours = val ? h : null),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _serviceInstructionsCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Service Details & Access Instructions',
              hintText: 'e.g. Apartment unit, gate code, supplies location, specific cleaning areas...',
              prefixIcon: const Icon(Icons.cleaning_services_rounded),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Deep cleaning required',
              'Bring own supplies',
              'Cooking for 4 people',
              'Call on arrival for gate code',
            ].map((tag) => ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.outlineVariant),
              onPressed: () {
                final cur = _serviceInstructionsCtrl.text.trim();
                setState(() {
                  _serviceInstructionsCtrl.text = cur.isEmpty ? tag : '$cur, $tag';
                });
              },
            )).toList(),
          ),
        ],

        // Type C: Queue Standing Fields
        if (_workflowType == 'queue_waiting') ...[
          const SizedBox(height: 20),
          TextFormField(
            controller: _venueNameCtrl,
            decoration: InputDecoration(
              labelText: 'Target Department / Counter / Booth Name',
              hintText: 'e.g. Visa Submission Hall Counter 4, NIMC Enrollment Desk...',
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Estimated Wait Duration (Hours)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0].map((h) {
              final sel = _durationHours == h;
              final label = h == 0.5 ? '30 mins' : (h % 1 == 0 ? '${h.toInt()} hr${h > 1 ? "s" : ""}' : '$h hrs');
              return ChoiceChip(
                label: Text(label),
                selected: sel,
                onSelected: (val) => setState(() => _durationHours = val ? h : null),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _serviceInstructionsCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Queue Handover & Stand-In Instructions',
              hintText: 'e.g. Call me when 3 people away from counter, take queue number token #24...',
              prefixIcon: const Icon(Icons.rule_rounded),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Take queue ticket at desk',
              'Call when 3 people away',
              'Hold spot until arrival',
              'Send photo of queue',
            ].map((tag) => ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.outlineVariant),
              onPressed: () {
                final cur = _serviceInstructionsCtrl.text.trim();
                setState(() {
                  _serviceInstructionsCtrl.text = cur.isEmpty ? tag : '$cur, $tag';
                });
              },
            )).toList(),
          ),
        ],

        // Contact info
        const SizedBox(height: 24),
        Text(
          _workflowType == 'pickup_delivery' ? 'Recipient Details (Optional)' : 'On-Site Contact (Optional)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _recipientNameCtrl,
          decoration: InputDecoration(
            labelText: _workflowType == 'pickup_delivery' ? 'Recipient Name' : 'Contact Person Name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _recipientPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: _workflowType == 'pickup_delivery' ? 'Recipient Phone' : 'Contact Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
          ),
        ),
        if (_workflowType == 'pickup_delivery') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _specialCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Special Delivery Instructions',
              hintText: 'e.g. Call before arrival, leave at reception...',
              prefixIcon: const Icon(Icons.info_outline_rounded),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _workflowPill(String mode, String label, ColorScheme colorScheme) {
    final sel = _workflowType == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _workflowType = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel ? const [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: sel ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep3(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your budget',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The runner receives 100% of your budget. A 15% platform fee is added.',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '₦${_budget.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Runner Reward',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _budget.toDouble(),
                  min: 500,
                  max: 50000,
                  divisions: 99,
                  onChanged: (v) => setState(() => _budget = v.round()),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [1000, 2000, 3500, 5000, 10000].map((amount) {
                  final isSelected = _budget == amount;
                  return GestureDetector(
                    onTap: () => setState(() => _budget = amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : colorScheme.outlineVariant,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '₦$amount',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? AppColors.primary : colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              _feeRow('Runner Payment', '₦$_budget', colorScheme),
              const SizedBox(height: 12),
              _feeRow('Platform Fee (15%)', '₦$_platformFee', colorScheme),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: colorScheme.outlineVariant),
              ),
              _feeRow('Total Amount', '₦$_total', colorScheme, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStep4(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Confirm',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review your errand details before posting to nearby runners.',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _reviewCard('Task Summary', [
          _reviewRow('Title', _titleCtrl.text, colorScheme),
          _reviewRow('Category', AppConstants.categoryLabels[_category] ?? _category, colorScheme),
          _reviewRow('Urgency', _urgency.toUpperCase(), colorScheme),
          if (_scheduledAt != null)
            _reviewRow(
              _workflowType == 'queue_waiting' ? 'Appointment Time' : 'Scheduled At',
              DateFormat('EEE, MMM d, yyyy • h:mm a').format(_scheduledAt!),
              colorScheme,
            ),
        ], colorScheme),
        const SizedBox(height: 16),
        if (_workflowType == 'pickup_delivery')
          _reviewCard('Route & Stops', [
            _reviewRow('Pickup', _pickupCtrl.text, colorScheme),
            if (_stops.isNotEmpty)
              _reviewRow('Intermediate Stops', '${_stops.length} stop(s)', colorScheme),
            _reviewRow('Destination', _destCtrl.text, colorScheme),
            if (_recipientNameCtrl.text.isNotEmpty)
              _reviewRow('Recipient', _recipientNameCtrl.text, colorScheme),
          ], colorScheme)
        else if (_workflowType == 'single_location')
          _reviewCard('Service Location & Duration', [
            _reviewRow('Service Location', _pickupCtrl.text, colorScheme),
            if (_durationHours != null)
              _reviewRow(
                'Estimated Duration',
                _durationHours == 0.5 ? '30 mins' : (_durationHours! % 1 == 0 ? '${_durationHours!.toInt()} hr(s)' : '$_durationHours hr(s)'),
                colorScheme,
              ),
            if (_serviceInstructionsCtrl.text.isNotEmpty)
              _reviewRow('Tasks / Access', _serviceInstructionsCtrl.text, colorScheme),
            if (_recipientNameCtrl.text.isNotEmpty)
              _reviewRow('On-Site Contact', _recipientNameCtrl.text, colorScheme),
          ], colorScheme)
        else
          _reviewCard('Queue Venue & Rules', [
            _reviewRow('Queue Venue', _pickupCtrl.text, colorScheme),
            if (_venueNameCtrl.text.isNotEmpty)
              _reviewRow('Desk / Office', _venueNameCtrl.text, colorScheme),
            if (_durationHours != null)
              _reviewRow(
                'Estimated Wait',
                _durationHours == 0.5 ? '30 mins' : (_durationHours! % 1 == 0 ? '${_durationHours!.toInt()} hr(s)' : '$_durationHours hr(s)'),
                colorScheme,
              ),
            if (_serviceInstructionsCtrl.text.isNotEmpty)
              _reviewRow('Instructions', _serviceInstructionsCtrl.text, colorScheme),
          ], colorScheme),
        const SizedBox(height: 16),
        _reviewCard('Payment Breakdown', [
          _reviewRow('Runner Reward', '₦$_budget', colorScheme),
          _reviewRow('Platform Fee', '₦$_platformFee', colorScheme),
          _reviewRow('Total Escrow', '₦$_total', colorScheme),
        ], colorScheme),
        const SizedBox(height: 20),
        Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (_activeGateways.isNotEmpty)
          ..._activeGateways.map((gw) {
            final id = (gw['id'] ?? '').toString();
            final title = (gw['title'] ?? gw['name'] ?? id).toString();
            final tagline = (gw['tagline'] ?? gw['description'] ?? 'Instant Online Payment').toString();
            final isBach = id == 'bach';
            final isPaystack = id == 'paystack';
            final badge = isBach ? 'Fast' : (isPaystack ? null : gw['badge']?.toString());
            final assetIcon = isBach
                ? 'assets/icons/bach.png'
                : (isPaystack ? 'assets/icons/paystack.png' : null);
            final icon = isBach
                ? Icons.flash_on_rounded
                : (isPaystack ? Icons.credit_card_rounded : Icons.payment_rounded);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _paymentMethodOption(
                id: id,
                title: 'Pay Now via $title',
                subtitle: tagline,
                badge: badge,
                icon: icon,
                assetIcon: assetIcon,
                colorScheme: colorScheme,
              ),
            );
          })
        else ...[
          _paymentMethodOption(
            id: 'paystack',
            title: 'Pay Now via Paystack',
            subtitle: 'Instant Card, Bank Transfer, Apple Pay, USSD',
            badge: null,
            icon: Icons.credit_card_rounded,
            assetIcon: 'assets/icons/paystack.png',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
          _paymentMethodOption(
            id: 'bach',
            title: 'Pay Now via Bachs',
            subtitle: 'Fast Checkout, Virtual Account, Cards & Seamless Pay',
            badge: 'Fast',
            icon: Icons.flash_on_rounded,
            assetIcon: 'assets/icons/bach.png',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
        ],
        _paymentMethodOption(
          id: 'wallet',
          title: 'Pay from Errand Wallet',
          subtitle: 'Available balance: ₦$_walletBalance',
          badge: _walletBalance < _total ? 'Insufficient' : null,
          icon: Icons.account_balance_wallet_rounded,
          colorScheme: colorScheme,
          disabled: _walletBalance < _total,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Funds will be held securely in escrow and only released when you confirm satisfactory delivery.',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _paymentMethodOption({
    required String id,
    required String title,
    required String subtitle,
    String? badge,
    required IconData icon,
    String? assetIcon,
    required ColorScheme colorScheme,
    bool disabled = false,
  }) {
    final selected = _paymentMethod == id;
    return InkWell(
      onTap: disabled ? null : () => setState(() => _paymentMethod = id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (disabled ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : colorScheme.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (disabled ? colorScheme.outlineVariant.withValues(alpha: 0.4) : colorScheme.outlineVariant),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: EdgeInsets.all(assetIcon != null ? 8 : 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: assetIcon != null
                  ? (id == 'bach'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(assetIcon, fit: BoxFit.contain),
                        )
                      : Image.asset(assetIcon, fit: BoxFit.contain))
                  : Icon(
                      icon,
                      color: disabled
                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                          : (selected ? AppColors.primary : colorScheme.onSurfaceVariant),
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: disabled ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5) : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badge == 'Recommended'
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badge == 'Recommended' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : colorScheme.outlineVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      items: AppConstants.categoryLabels.entries.map((e) => DropdownMenuItem(
        value: e.key,
        child: Text('${AppConstants.categoryEmojis[e.key] ?? "✨"} ${e.value}'),
      )).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _category = v;
          if (v == 'queue_standing') {
            _workflowType = 'queue_waiting';
          } else if (v == 'personal_assistance' || v == 'domestic_chores') {
            _workflowType = 'single_location';
          } else if (v == 'custom_errand') {
            // preserve existing
          } else {
            _workflowType = 'pickup_delivery';
          }
        });
      },
    );
  }

  Future<void> _pickScheduledDateTime(ColorScheme colorScheme) async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 60));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAt != null && _scheduledAt!.isAfter(now) ? _scheduledAt! : now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT APPOINTMENT / SCHEDULE DATE',
      confirmText: 'NEXT: SELECT TIME',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final initialTime = _scheduledAt != null
        ? TimeOfDay(hour: _scheduledAt!.hour, minute: _scheduledAt!.minute)
        : TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30)));

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'SELECT APPOINTMENT / SCHEDULE TIME',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (combined.isBefore(now)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a future appointment time')),
        );
      }
      return;
    }

    setState(() {
      _scheduledAt = combined;
      _urgency = 'scheduled';
    });
  }

  Widget _urgencyChip(String value, String label, ColorScheme colorScheme) {
    final selected = _urgency == value;
    return GestureDetector(
      onTap: () {
        setState(() => _urgency = value);
        if (value == 'scheduled' && _scheduledAt == null) {
          _pickScheduledDateTime(colorScheme);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _feeRow(String label, String value, ColorScheme colorScheme, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: bold ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            color: bold ? AppColors.primary : colorScheme.onSurface,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(String title, List<Widget> rows, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.primary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
