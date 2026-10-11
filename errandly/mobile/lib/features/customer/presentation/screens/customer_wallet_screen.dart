import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
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

  Future<void> _fundAmount(int amount, ColorScheme colorScheme) async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.initCustomerPayment({'amount': amount, 'gateway': 'paystack'});
      final data = res.data;
      final reference = data['reference']?.toString() ?? data['data']?['reference']?.toString();
      if (reference == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Could not start payment. Check backend Paystack config.'), backgroundColor: colorScheme.error),
        );
        return;
      }
      final verified = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Verify payment', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
          content: Text('After paying, tap Verify to credit wallet.\nReference: $reference', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Later', style: TextStyle(color: colorScheme.onSurfaceVariant))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (verified == true) {
        await api.verifyCustomerPayment({'reference': reference, 'gateway': 'paystack'});
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Wallet funded!'), backgroundColor: Colors.green.shade600),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: colorScheme.error),
        );
      }
    }
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

  void _showFundWallet(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(32, 32, 32, 32 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fund Wallet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: [1000, 2000, 5000, 10000, 20000].map((amount) => GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _fundAmount(amount, colorScheme);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text('₦$amount', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 16)),
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Enter Custom Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 240,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    iconTheme: IconThemeData(color: colorScheme.onSurface),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Wallet Balance', style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text(
                                  '₦${(_wallet?['balance'] ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                                  style: TextStyle(color: colorScheme.onPrimary, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: colorScheme.onPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                  child: Text('₦${_wallet?['escrow_balance'] ?? 0} in escrow', style: TextStyle(color: colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fund button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () => _showFundWallet(colorScheme),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Fund Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Stats
                          Row(
                            children: [
                              Expanded(child: _StatCard(label: 'Total Funded', value: '₦${_wallet?['total_funded'] ?? 0}', icon: Icons.trending_up_rounded, color: Colors.green.shade600, colorScheme: colorScheme)),
                              const SizedBox(width: 16),
                              Expanded(child: _StatCard(label: 'In Escrow', value: '₦${_wallet?['escrow_balance'] ?? 0}', icon: Icons.lock_rounded, color: Colors.orange.shade600, colorScheme: colorScheme)),
                            ],
                          ),

                          const SizedBox(height: 40),
                          Text('Transaction History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _TransactionItem(tx: _transactions[i], colorScheme: colorScheme),
                      childCount: _transactions.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
  final ColorScheme colorScheme;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: colorScheme.onSurface, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> tx;
  final ColorScheme colorScheme;
  
  const _TransactionItem({required this.tx, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx['direction'] == 'credit';
    final txColor = isCredit ? Colors.green.shade600 : colorScheme.error;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
            decoration: BoxDecoration(
              color: txColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: txColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(tx['type'] ?? '', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₦${tx['amount'] ?? 0}',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: txColor),
          ),
        ],
      ),
    );
  }
}
