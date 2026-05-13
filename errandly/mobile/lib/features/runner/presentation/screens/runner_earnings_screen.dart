import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class RunnerEarningsScreen extends StatefulWidget {
  const RunnerEarningsScreen({super.key});

  @override
  State<RunnerEarningsScreen> createState() => _RunnerEarningsScreenState();
}

class _RunnerEarningsScreenState extends State<RunnerEarningsScreen> {
  Map<String, dynamic>? _earnings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.runnerEarnings();
      setState(() {
        _earnings = res.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showWithdraw() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.runnerSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        int amount = 1000;
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Withdraw Earnings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [1000, 2000, 5000, 10000].map((a) => GestureDetector(
                    onTap: () => setState(() => amount = a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: amount == a ? AppColors.primary : AppColors.navyLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('₦$a', style: TextStyle(color: amount == a ? Colors.white : AppColors.runnerTextMuted, fontWeight: FontWeight.w700)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final api = getIt<ApiClient>();
                        await api.withdrawEarnings(amount);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Withdrawal requested! Processing within 24 hours.'), backgroundColor: AppColors.success),
                          );
                          _load();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
                        }
                      }
                    },
                    child: Text('Withdraw ₦$amount'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.runnerBackground,
      appBar: AppBar(title: const Text('Earnings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.runnerSurface,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Balance card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('₦${_earnings?['wallet_balance'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: _showWithdraw,
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                              child: const Text('Withdraw to Bank Account', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Earnings summary
                    Row(
                      children: [
                        Expanded(child: _EarningsCard(label: 'Today', value: '₦${_earnings?['today'] ?? 0}')),
                        const SizedBox(width: 12),
                        Expanded(child: _EarningsCard(label: 'This Week', value: '₦${_earnings?['this_week'] ?? 0}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _EarningsCard(label: 'This Month', value: '₦${_earnings?['this_month'] ?? 0}')),
                        const SizedBox(width: 12),
                        Expanded(child: _EarningsCard(label: 'All Time', value: '₦${_earnings?['total'] ?? 0}')),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Align(alignment: Alignment.centerLeft, child: Text('Recent Transactions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 12),

                    ...(_earnings?['recent_transactions'] as List<dynamic>? ?? []).map((tx) {
                      final isCredit = tx['direction'] == 'credit';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.runnerSurface, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: (isCredit ? AppColors.success : AppColors.danger).withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? AppColors.success : AppColors.danger, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tx['description'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text(
                              '${isCredit ? '+' : '-'}₦${tx['amount'] ?? 0}',
                              style: TextStyle(color: isCredit ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final String value;

  const _EarningsCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.runnerSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.runnerBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.runnerTextMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
