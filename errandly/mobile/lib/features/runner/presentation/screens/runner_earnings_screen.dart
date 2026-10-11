import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart';
import 'runner_bank_account_screen.dart';

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

  void _showWithdraw(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) {
        int amount = 1000;
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: EdgeInsets.fromLTRB(32, 32, 32, 32 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Withdraw Earnings', style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [1000, 2000, 5000, 10000].map((a) => GestureDetector(
                    onTap: () => setState(() => amount = a),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: amount == a ? colorScheme.primary : colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: amount == a ? Border.all(color: colorScheme.primary) : Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Text('₦$a', style: TextStyle(color: amount == a ? colorScheme.onPrimary : colorScheme.onSurfaceVariant, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final api = getIt<ApiClient>();
                        await api.withdrawEarnings(amount);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Withdrawal requested! Processing within 24 hours.'), backgroundColor: Colors.green.shade600),
                          );
                          _load();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: colorScheme.error));
                        }
                      }
                    },
                    child: Text('Withdraw ₦$amount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Earnings', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Balance card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          Text('Available Balance', style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('₦${_earnings?['wallet_balance'] ?? 0}', style: TextStyle(color: colorScheme.onPrimary, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => _showWithdraw(colorScheme),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.onPrimary,
                                foregroundColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Withdraw to Bank Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerBankAccountScreen())),
                              child: Text('Manage bank account', style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9), fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Earnings summary
                    Row(
                      children: [
                        Expanded(child: _EarningsCard(label: 'Today', value: '₦${_earnings?['today'] ?? 0}', colorScheme: colorScheme)),
                        const SizedBox(width: 16),
                        Expanded(child: _EarningsCard(label: 'This Week', value: '₦${_earnings?['this_week'] ?? 0}', colorScheme: colorScheme)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _EarningsCard(label: 'This Month', value: '₦${_earnings?['this_month'] ?? 0}', colorScheme: colorScheme)),
                        const SizedBox(width: 16),
                        Expanded(child: _EarningsCard(label: 'All Time', value: '₦${_earnings?['total'] ?? 0}', colorScheme: colorScheme)),
                      ],
                    ),

                    const SizedBox(height: 36),
                    Align(alignment: Alignment.centerLeft, child: Text('Recent Transactions', style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
                    const SizedBox(height: 16),

                    ...(_earnings?['recent_transactions'] as List<dynamic>? ?? []).map((tx) {
                      final isCredit = tx['direction'] == 'credit';
                      final txColor = isCredit ? Colors.green.shade600 : colorScheme.error;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.4), 
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: txColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: txColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(tx['description'] ?? '', style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text(
                              '${isCredit ? '+' : '-'}₦${tx['amount'] ?? 0}',
                              style: TextStyle(color: txColor, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
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
  final ColorScheme colorScheme;

  const _EarningsCard({required this.label, required this.value, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: colorScheme.outlineVariant)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}
