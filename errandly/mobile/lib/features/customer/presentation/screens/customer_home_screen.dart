import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../../core/constants/app_constants.dart';
import 'create_errand_screen.dart';
import 'errand_detail_screen.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.navy,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.navy, AppColors.navyLight],
                    ),
                  ),
                  child: SafeArea(
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
                                  const Text('Good day! 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _dashboard?['user']?['first_name'] ?? 'Customer',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              Stack(
                                children: [
                                  const CircleAvatar(backgroundColor: AppColors.primary, radius: 22, child: Icon(Icons.person, color: Colors.white)),
                                  Positioned(
                                    right: 0, top: 0,
                                    child: Container(
                                      width: 10, height: 10,
                                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _WalletBar(balance: _dashboard?['wallet_balance'] ?? 0),
                        ],
                      ),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Post a New Errand', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                  Text('Find a verified runner in minutes', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Categories
                    const Text('What do you need?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
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

                    const SizedBox(height: 24),

                    // Active errand
                    if (_dashboard?['active_errand'] != null) ...[
                      const Text('Active Errand', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      _ActiveErrandCard(errand: _dashboard!['active_errand']),
                      const SizedBox(height: 24),
                    ],

                    // Quick actions
                    const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.account_balance_wallet_rounded, label: 'Fund Wallet', color: AppColors.info, onTap: () {})),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(icon: Icons.support_agent_rounded, label: 'Support', color: AppColors.success, onTap: () {})),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(icon: Icons.report_problem_outlined, label: 'Report Issue', color: AppColors.danger, onTap: () {})),
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
  const _WalletBar({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('₦${balance.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Text('Fund', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
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

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ErrandDetailScreen(errandId: errand['id']))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(errand['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryFaded, borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (errand['runner'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircleAvatar(backgroundColor: AppColors.primary, radius: 14, child: Icon(Icons.person, color: Colors.white, size: 16)),
                  const SizedBox(width: 8),
                  Text(errand['runner']['full_name'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                  const Text('Live', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ErrandDetailScreen(errandId: errand['id']))),
                child: const Text('Track Errand', style: TextStyle(fontSize: 14)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
