import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart';
import '../../../../core/constants/app_constants.dart';
import 'create_errand_screen.dart';
import 'errand_detail_screen.dart';
import 'customer_assistant_screen.dart';
import 'customer_wallet_screen.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/services/notification_inbox_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  Map<String, dynamic>? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    NotificationInboxService.refresh(getIt<ApiClient>());
  }

  Future<void> _loadDashboard() async {
    try {
      final api = getIt<ApiClient>();
      final response = await api.customerDashboard();
      setState(() {
        _dashboard = response.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Good day! 👋', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  _dashboard?['user']?['first_name'] ?? 'Customer',
                                  style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                NotificationBellButton(
                                  onOpened: () => NotificationInboxService.refresh(getIt<ApiClient>()),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                                  radius: 22,
                                  child: Icon(Icons.person, color: colorScheme.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _WalletBar(
                          balance: _dashboard?['wallet_balance'] ?? 0,
                          onFund: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerWalletScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post errand button
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateErrandScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.add, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Post a New Errand', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                  SizedBox(height: 4),
                                  Text('Find a verified runner near you', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Categories
                    Text('What do you need?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppConstants.categoryLabels.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final entry = AppConstants.categoryLabels.entries.elementAt(i);
                          final emoji = AppConstants.categoryEmojis[entry.key] ?? '✨';
                          return _CategoryCard(key: ValueKey(entry.key), emoji: emoji, label: entry.value, onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const CreateErrandScreen(),
                            ));
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Active errand
                    if (_dashboard?['active_errand'] != null) ...[
                      Text('Active Errand', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                      const SizedBox(height: 16),
                      _ActiveErrandCard(errand: _dashboard!['active_errand']),
                      const SizedBox(height: 32),
                    ],

                    // Quick actions
                    Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.account_balance_wallet_rounded, label: 'Fund Wallet', color: Colors.blue, onTap: () {})),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.support_agent_rounded,
                            label: 'AI Assistant',
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CustomerAssistantScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(icon: Icons.report_problem_outlined, label: 'Report Issue', color: Colors.red, onTap: () {})),
                      ],
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
}

class _WalletBar extends StatelessWidget {
  final int balance;
  final VoidCallback? onFund;
  const _WalletBar({required this.balance, this.onFund});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Text('₦${balance.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(
            onTap: onFund,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('Fund', style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _CategoryCard({super.key, required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.5), shape: BoxShape.circle),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
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
    final status = errand['status'] ?? 'pending';
    final statusLabel = AppConstants.statusLabels[status] ?? status;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ErrandDetailScreen(errandPublicId: errand['public_id']))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(errand['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colorScheme.onSurface))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(statusLabel, style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (errand['runner'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: colorScheme.primary.withOpacity(0.2), radius: 18, child: Icon(Icons.person, color: colorScheme.primary, size: 20)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(errand['runner']['full_name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                        Text('Verified Runner', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 20),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ErrandDetailScreen(errandPublicId: errand['public_id']))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.onSurface,
                  foregroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Track Live Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurface, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
