import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
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

  Future<void> _toggleOnline() async {
    setState(() => _toggling = true);
    try {
      final api = getIt<ApiClient>();
      final isOnline = _dashboard?['runner']?['is_online'] ?? false;
      await api.updateAvailability({'is_online': !isOnline});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      setState(() => _toggling = false);
    }
  }

  Future<void> _acceptErrand(String publicId) async {
    try {
      final api = getIt<ApiClient>();
      await api.acceptErrand(publicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errand accepted! Navigate to pickup.'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final runner = _dashboard?['runner'];
    final isOnline = runner?['is_online'] ?? false;
    final activeErrand = _dashboard?['active_errand'];

    return Scaffold(
      backgroundColor: AppColors.runnerBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.runnerSurface,
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
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
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                Text(isOnline ? 'You are receiving errands' : 'Go online to start earning',
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                              ],
                            ),
                          ),
                          NotificationBellButton(
                            onOpened: () => NotificationInboxService.refresh(getIt<ApiClient>()),
                          ),
                          const SizedBox(width: 8),
                          const CircleAvatar(backgroundColor: AppColors.primary, radius: 22, child: Icon(Icons.person, color: Colors.white)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Online toggle
                      GestureDetector(
                        onTap: _toggling ? null : _toggleOnline,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOnline ? [const Color(0xFF16A34A), const Color(0xFF22C55E)] : [AppColors.navyLight, AppColors.navyMid],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.white : Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isOnline ? 'You are Online' : 'You are Offline', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                    Text(isOnline ? 'Tap to go offline' : 'Tap to go online', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                  ],
                                ),
                              ),
                              _toggling
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Icon(isOnline ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: Colors.white, size: 36),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        children: [
                          _StatCard(label: "Today's Earnings", value: '₦${_dashboard?['today_earnings'] ?? 0}', color: AppColors.primary),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Trust Score', value: '${(runner?['trust_score'] ?? 70).toStringAsFixed(0)}/100', color: AppColors.warning),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Active errand
                      if (activeErrand != null) ...[
                        const Text('Active Errand', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _ActiveErrandCard(errand: activeErrand),
                        const SizedBox(height: 20),
                      ],

                      // Available errands
                      if (isOnline && activeErrand == null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Available Errands', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            GestureDetector(
                              onTap: _loadAvailableErrands,
                              child: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_availableErrands.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: AppColors.runnerSurface, borderRadius: BorderRadius.circular(16)),
                            child: const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined, color: AppColors.runnerTextMuted, size: 48),
                                  SizedBox(height: 8),
                                  Text('No errands nearby', style: TextStyle(color: AppColors.runnerTextMuted)),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._availableErrands.map((errand) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AvailableErrandCard(errand: errand, onAccept: () => _acceptErrand(errand['public_id'])),
                          )),
                      ],
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

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.runnerSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.runnerBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.runnerTextMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _ActiveErrandCard extends StatelessWidget {
  final Map<String, dynamic> errand;
  const _ActiveErrandCard({required this.errand});

  @override
  Widget build(BuildContext context) {
    final status = errand['status'] ?? '';
    final statusLabel = AppConstants.statusLabels[status] ?? status;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RunnerErrandDetailScreen(errandPublicId: errand['public_id']))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(statusLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Text('₦${errand['runner_earnings'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
            Text(errand['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Tap to manage errand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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

  const _AvailableErrandCard({required this.errand, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final category = errand['category'] ?? 'custom_errand';
    final emoji = AppConstants.categoryEmojis[category] ?? '✨';
    final isUrgent = errand['urgency'] == 'urgent';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.runnerSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUrgent ? AppColors.danger.withOpacity(0.5) : AppColors.runnerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errand['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${errand['distance_km']?.toStringAsFixed(1) ?? '?'} km away', style: const TextStyle(color: AppColors.runnerTextMuted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₦${errand['budget'] ?? 0}', style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('URGENT', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Accept', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.runnerTextMuted,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Text('Skip', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
