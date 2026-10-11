import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../main.dart';
import 'runner_errand_detail_screen.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/services/notification_inbox_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
    NotificationInboxService.refresh(getIt<ApiClient>());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();
      final res = await api.runnerDashboard();
      setState(() {
        _dashboard = res.data;
        _loading = false;
      });

      if (_dashboard?['runner']?['is_online'] == true) {
        _loadAvailableErrands();
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAvailableErrands() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.getAvailableErrands();
      setState(() => _availableErrands = res.data['data'] ?? []);
    } catch (e) {}
  }

  Future<void> _toggleOnline(ColorScheme colorScheme) async {
    setState(() => _toggling = true);
    try {
      final api = getIt<ApiClient>();
      final isOnline = _dashboard?['runner']?['is_online'] ?? false;
      await api.updateAvailability({'is_online': !isOnline});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: colorScheme.error),
        );
      }
    } finally {
      setState(() => _toggling = false);
    }
  }

  Future<void> _acceptErrand(String publicId, ColorScheme colorScheme) async {
    try {
      final api = getIt<ApiClient>();
      await api.acceptErrand(publicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Errand accepted! Navigate to pickup.'), backgroundColor: Colors.green.shade600),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: colorScheme.error),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          onRefresh: _load,
          child: _loading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hello, ${runner?['full_name']?.toString().split(' ').first ?? 'Runner'}! 👋',
                                  style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                const SizedBox(height: 4),
                                Text(isOnline ? 'You are receiving errands' : 'Go online to start earning',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                              ],
                            ),
                          ),
                          NotificationBellButton(
                            onOpened: () => NotificationInboxService.refresh(getIt<ApiClient>()),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(backgroundColor: colorScheme.primary, radius: 24, child: Icon(Icons.person, color: colorScheme.onPrimary)),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Online toggle
                      GestureDetector(
                        onTap: _toggling ? null : () => _toggleOnline(colorScheme),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOnline ? [Colors.green.shade500, Colors.green.shade600] : [colorScheme.surfaceVariant, colorScheme.surfaceVariant.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isOnline ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))] : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16, height: 16,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.white : colorScheme.onSurfaceVariant.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isOnline ? 'You are Online' : 'You are Offline', style: TextStyle(color: isOnline ? Colors.white : colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text(isOnline ? 'Tap to go offline' : 'Tap to go online', style: TextStyle(color: isOnline ? Colors.white.withOpacity(0.8) : colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              _toggling
                                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: isOnline ? Colors.white : colorScheme.primary, strokeWidth: 3))
                                  : Icon(isOnline ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: isOnline ? Colors.white : colorScheme.onSurfaceVariant, size: 40),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stats row
                      Row(
                        children: [
                          _StatCard(label: "Today's Earnings", value: '₦${_dashboard?['today_earnings'] ?? 0}', color: colorScheme.primary, colorScheme: colorScheme),
                          const SizedBox(width: 16),
                          _StatCard(label: 'Trust Score', value: '${(runner?['trust_score'] ?? 70).toStringAsFixed(0)}/100', color: Colors.orange, colorScheme: colorScheme),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Active errand
                      if (activeErrand != null) ...[
                        Text('Active Errand', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        _ActiveErrandCard(errand: activeErrand, colorScheme: colorScheme),
                        const SizedBox(height: 32),
                      ],

                      // Available errands
                      if (isOnline && activeErrand == null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Available Errands', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                            Container(
                              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: IconButton(
                                onPressed: _loadAvailableErrands,
                                icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_availableErrands.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outlineVariant)),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined, color: colorScheme.onSurfaceVariant, size: 56),
                                  const SizedBox(height: 16),
                                  Text('No errands nearby', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._availableErrands.map((errand) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _AvailableErrandCard(errand: errand, onAccept: () => _acceptErrand(errand['public_id'], colorScheme), colorScheme: colorScheme),
                          )),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ColorScheme colorScheme;

  const _StatCard({required this.label, required this.value, required this.color, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outlineVariant)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RunnerErrandDetailScreen(errandPublicId: errand['public_id']))),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt_rounded, color: colorScheme.onPrimary, size: 24),
                const SizedBox(width: 12),
                Text(statusLabel, style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('₦${errand['runner_earnings'] ?? 0}', style: TextStyle(color: colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            Text(errand['title'] ?? '', style: TextStyle(color: colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: colorScheme.onPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward_rounded, color: colorScheme.onPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text('Tap to manage errand', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
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

  const _AvailableErrandCard({required this.errand, required this.onAccept, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final category = errand['category'] ?? 'custom_errand';
    final emoji = AppConstants.categoryEmojis[category] ?? '✨';
    final isUrgent = errand['urgency'] == 'urgent';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isUrgent ? colorScheme.error.withOpacity(0.5) : colorScheme.outlineVariant, width: isUrgent ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colorScheme.surfaceVariant, shape: BoxShape.circle),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errand['title'] ?? '', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${errand['distance_km']?.toStringAsFixed(1) ?? '?'} km away', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₦${errand['budget'] ?? 0}', style: TextStyle(color: colorScheme.primary, fontSize: 22, fontWeight: FontWeight.w900)),
                  if (isUrgent)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                      child: Text('URGENT', style: TextStyle(color: colorScheme.error, fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Skip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
