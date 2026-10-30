import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/runner_location_tracker.dart';
import '../../../../main.dart';
import 'runner_errand_detail_screen.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/services/notification_inbox_service.dart';
import '../../../../core/services/realtime_service.dart';

class RunnerHomeScreen extends StatefulWidget {
  const RunnerHomeScreen({super.key});

  @override
  State<RunnerHomeScreen> createState() => _RunnerHomeScreenState();
}

class _RunnerHomeScreenState extends State<RunnerHomeScreen> {
  Map<String, dynamic>? _dashboard;
  List<dynamic> _availableErrands = [];
  bool _loading = true;
  bool _toggling = false;
  void Function(String, dynamic)? _realtimeListener;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationInboxService.refresh(getIt<ApiClient>());
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeListener = (event, data) {
      if (!mounted) return;
      if (event == 'ErrandCreated' || event == 'errand_offer') {
        _loadAvailableErrands();
        final title = data is Map ? (data['title'] ?? 'New errand') : 'New errand';
        final budget = data is Map ? (data['budget'] ?? '') : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚡ New Errand Available: $title ${budget != '' ? '(₦$budget)' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };
    RealtimeService.instance.subscribeAvailableErrands(onEvent: _realtimeListener!);
  }

  @override
  void dispose() {
    if (_realtimeListener != null) {
      RealtimeService.instance.unsubscribeAvailableErrands(onEvent: _realtimeListener!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();
      final res = await api.runnerDashboard();
      if (mounted) {
        setState(() {
          _dashboard = res.data;
          _loading = false;
        });
      }

      if (_dashboard?['active_errand'] != null) {
        final activeErrand = _dashboard!['active_errand'];
        final publicId = activeErrand['public_id']?.toString();
        final st = activeErrand['status']?.toString() ?? '';
        final isTrackingStatus = [
          'accepted',
          'assigned',
          'runner_en_route',
          'arrived',
          'item_picked',
          'in_progress',
        ].contains(st);
        if (publicId != null && isTrackingStatus) {
          RunnerLocationTracker.instance.startTracking(errandPublicId: publicId);
        } else if (['completed', 'cancelled', 'disputed'].contains(st)) {
          RunnerLocationTracker.instance.stopTracking();
        }
      }

      if (_dashboard?['runner']?['is_online'] == true) {
        _loadAvailableErrands();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAvailableErrands() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.getAvailableErrands();
      if (mounted) {
        setState(() => _availableErrands = res.data['data'] ?? []);
      }
    } catch (_) {}
  }

  Future<void> _toggleOnline(ColorScheme colorScheme) async {
    setState(() => _toggling = true);
    try {
      final api = getIt<ApiClient>();
      final isOnline = _dashboard?['runner']?['is_online'] ?? false;
      if (isOnline) {
        RunnerLocationTracker.instance.stopTracking();
      }
      await api.updateAvailability({'is_online': !isOnline});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _acceptErrand(String publicId, ColorScheme colorScheme) async {
    try {
      final api = getIt<ApiClient>();
      await api.acceptErrand(publicId);
      RunnerLocationTracker.instance.startTracking(errandPublicId: publicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errand accepted! Head to pickup location.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final runner = _dashboard?['runner'];
    final isOnline = runner?['is_online'] ?? false;
    final activeErrand = _dashboard?['active_errand'];
    final runnerName = runner?['full_name']?.toString().split(' ').first ?? 'Runner';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Icon(Icons.two_wheeler_rounded, color: colorScheme.primary, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.success.withValues(alpha: 0.15)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isOnline ? AppColors.success : colorScheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RUNNER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hey, $runnerName!',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: NotificationBellButton(
                onOpened: () => NotificationInboxService.refresh(getIt<ApiClient>()),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        onRefresh: _load,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Online/Offline Status Toggle Card
                    GestureDetector(
                      onTap: _toggling ? null : () => _toggleOnline(colorScheme),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isOnline
                              ? const LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isOnline ? null : colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isOnline
                                ? Colors.transparent
                                : colorScheme.outlineVariant,
                          ),
                          boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  isOnline ? Icons.radar_rounded : Icons.power_settings_new_rounded,
                                  color: isOnline ? Colors.white : colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOnline ? 'You Are Online' : 'You Are Offline',
                                    style: TextStyle(
                                      color: isOnline ? Colors.white : colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isOnline
                                        ? 'Receiving orders nearby • Tap to rest'
                                        : 'Go online to receive nearby delivery tasks',
                                    style: TextStyle(
                                      color: isOnline
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _toggling
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.white : AppColors.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isOnline ? 'Offline' : 'Go Live',
                                      style: TextStyle(
                                        color: isOnline ? const Color(0xFF065F46) : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats Grid Row (Today's Earnings & Trust Score)
                    Row(
                      children: [
                        _StatCard(
                          icon: Icons.payments_rounded,
                          label: "TODAY'S EARNINGS",
                          value: '₦${(_dashboard?['today_earnings'] ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                          color: AppColors.primary,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.shield_rounded,
                          label: 'TRUST SCORE',
                          value: '${(runner?['trust_score'] ?? 70).toStringAsFixed(0)}/100',
                          color: AppColors.success,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Active Errand Card (if runner has an in-flight delivery)
                    if (activeErrand != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Task',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'IN PROGRESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ActiveErrandCard(errand: activeErrand, colorScheme: colorScheme),
                      const SizedBox(height: 28),
                    ],

                    // Available Errands Section
                    if (isOnline && activeErrand == null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Errands',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                '${_availableErrands.length} opportunities nearby',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: _loadAvailableErrands,
                            icon: const Icon(Icons.refresh_rounded),
                            color: AppColors.primary,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_availableErrands.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.radar_rounded, color: colorScheme.onSurfaceVariant, size: 40),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Searching for nearby requests...',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Stay in busy commercial areas to receive delivery requests faster.',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ..._availableErrands.map(
                          (errand) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _AvailableErrandCard(
                              errand: errand,
                              onAccept: () => _acceptErrand(errand['public_id'], colorScheme),
                              colorScheme: colorScheme,
                            ),
                          ),
                        ),
                    ] else if (!isOnline) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.offline_bolt_outlined, color: colorScheme.onSurfaceVariant, size: 48),
                            const SizedBox(height: 14),
                            Text(
                              'You Are Currently Offline',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Switch your status to online using the button above to receive real-time errand requests.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme colorScheme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveErrandCard extends StatelessWidget {
  final Map<String, dynamic> errand;
  final ColorScheme colorScheme;
  const _ActiveErrandCard({required this.errand, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final status = errand['status'] ?? '';
    final statusLabel = AppConstants.statusLabels[status] ?? status;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RunnerErrandDetailScreen(errandPublicId: errand['public_id']),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: RunnerLocationTracker.instance.isTrackingNotifier,
                      builder: (context, isTracking, _) {
                        if (!isTracking) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.satellite_alt_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'GPS LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  '₦${errand['runner_earnings'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              errand['title'] ?? 'Active Task',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Builder(
              builder: (context) {
                final displayAddr = errand['destination_address'] ?? errand['pickup_address'];
                if (displayAddr == null || displayAddr.toString().trim().isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displayAddr.toString(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Manage Active Errand',
                    style: TextStyle(
                      color: Color(0xFF0E0F13),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableErrandCard extends StatelessWidget {
  final Map<String, dynamic> errand;
  final VoidCallback onAccept;
  final ColorScheme colorScheme;

  const _AvailableErrandCard({
    required this.errand,
    required this.onAccept,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final category = errand['category'] ?? 'custom_errand';
    final emoji = AppConstants.categoryEmojis[category] ?? '✨';
    final isUrgent = errand['urgency'] == 'urgent';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUrgent ? AppColors.danger.withValues(alpha: 0.6) : colorScheme.outlineVariant,
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errand['title'] ?? 'New Errand',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.near_me_rounded, color: colorScheme.onSurfaceVariant, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${errand['distance_km']?.toStringAsFixed(1) ?? '2.4'} km away',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦${errand['runner_earnings'] ?? errand['budget'] ?? 0}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Payout',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (errand['pickup_address'] != null || errand['destination_address'] != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  if (errand['pickup_address'] != null)
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked_rounded, color: AppColors.primary, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errand['pickup_address'],
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (errand['destination_address'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errand['destination_address'],
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accept Errand', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RunnerErrandDetailScreen(errandPublicId: errand['public_id']),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
