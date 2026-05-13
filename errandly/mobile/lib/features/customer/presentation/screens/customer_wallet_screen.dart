import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final walletRes = await api.getWallet();
      final txRes = await api.getTransactions();
      setState(() {
        _wallet = walletRes.data;
        _transactions = txRes.data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showFundWallet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fund Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [1000, 2000, 5000, 10000, 20000].map((amount) => GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Redirecting to payment for ₦$amount...'), backgroundColor: AppColors.primary),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFaded,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text('₦$amount', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Enter Custom Amount'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              backgroundColor: AppColors.navy,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.navy, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            '₦${(_wallet?['balance'] ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text('₦${_wallet?['escrow_balance'] ?? 0} in escrow', style: const TextStyle(color: Colors.white60, fontSize: 12)),
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
                    // Fund button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showFundWallet,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Fund Wallet'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'Total Funded', value: '₦${_wallet?['total_funded'] ?? 0}', icon: Icons.trending_up_rounded, color: AppColors.success)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'In Escrow', value: '₦${_wallet?['escrow_balance'] ?? 0}', icon: Icons.lock_rounded, color: AppColors.warning)),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TransactionItem(tx: _transactions[i]),
                childCount: _transactions.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx['direction'] == 'credit';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : AppColors.danger).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isCredit ? AppColors.success : AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(tx['type'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₦${tx['amount'] ?? 0}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isCredit ? AppColors.success : AppColors.danger),
          ),
        ],
      ),
    );
  }
}
