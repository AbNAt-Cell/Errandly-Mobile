import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/url_helper.dart';
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
  List<Map<String, dynamic>> _activeGateways = [];
  String _defaultGateway = 'paystack';

  Color _getGatewayColor(String id) {
    return switch (id.toLowerCase()) {
      'bach' => const Color(0xFF10B981),
      'paystack' => AppColors.primary,
      'flutterwave' => const Color(0xFFF5A623),
      'stripe' => const Color(0xFF635BFF),
      _ => AppColors.primary,
    };
  }

  IconData _getGatewayIcon(String id) {
    return switch (id.toLowerCase()) {
      'bach' => Icons.flash_on_rounded,
      'paystack' => Icons.credit_card_rounded,
      'flutterwave' => Icons.payment_rounded,
      'stripe' => Icons.credit_card_rounded,
      _ => Icons.account_balance_wallet_rounded,
    };
  }

  String? _getGatewayAsset(String id) {
    return switch (id.toLowerCase()) {
      'bach' => 'assets/icons/bach.png',
      'paystack' => 'assets/icons/paystack.png',
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _fundAmount(int amount, ColorScheme colorScheme, {String gateway = 'paystack'}) async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.initCustomerPayment({'amount': amount, 'gateway': gateway});
      final data = res.data;
      final payload = data is Map ? (data['data'] is Map ? data['data'] : data) : {};
      final reference = payload['reference']?.toString() ?? data['reference']?.toString();
      final authUrl = payload['authorization_url']?.toString() ??
          payload['checkout_url']?.toString() ??
          payload['payment_url']?.toString();
      if (reference == null) {
        if (mounted) {
          final gwName = gateway == 'bach' ? 'Bachs' : 'Paystack';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not start payment. Check backend $gwName config.'),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      if (authUrl != null && authUrl.isNotEmpty) {
        await UrlHelper.open(context, authUrl);
      }
      if (!mounted) return;
      final verified = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Verify Payment',
            style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          ),
          content: Text(
            'After completing payment in the browser, tap Verify to credit your wallet.\n\nGateway: ${gateway == 'bach' ? 'Bachs' : 'Paystack'}\nReference: $reference',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Later', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (verified == true) {
        await api.verifyCustomerPayment({'reference': reference, 'gateway': gateway});
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet funded successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.formatErrorMessage(e)),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final walletRes = await api.getWallet();
      final txRes = await api.getTransactions();

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
        // Fallback default gateways if offline
        _activeGateways = [
          {'id': 'paystack', 'name': 'Paystack', 'title': 'Paystack', 'tagline': 'Cards & Transfer', 'badge': 'POPULAR'},
          {'id': 'bach', 'name': 'Bachs', 'title': 'Bachs Pay', 'tagline': 'Fast Checkout', 'badge': 'FAST'},
        ];
      }

      if (mounted) {
        setState(() {
          _wallet = walletRes.data;
          _transactions = txRes.data['data'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFundWallet(ColorScheme colorScheme) {
    final availableGateways = _activeGateways.isNotEmpty
        ? _activeGateways
        : [
            {'id': 'paystack', 'name': 'Paystack', 'title': 'Paystack', 'tagline': 'Cards & Transfer', 'badge': 'POPULAR'},
            {'id': 'bach', 'name': 'Bachs', 'title': 'Bachs Pay', 'tagline': 'Fast Checkout', 'badge': 'FAST'},
          ];

    String selectedGateway = availableGateways.any((g) => g['id'] == _defaultGateway)
        ? _defaultGateway
        : (availableGateways.isNotEmpty ? availableGateways.first['id'].toString() : 'paystack');
    int selectedAmount = 5000;
    final customAmountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final entered = int.tryParse(customAmountCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), ''));
          final currentAmount = entered != null && entered > 0 ? entered : selectedAmount;
          final formattedAmount = currentAmount > 0
              ? ' (₦${currentAmount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')})'
              : '';

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 28 + MediaQuery.of(modalContext).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fund Your Wallet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose your preferred payment processor and amount.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  // Dynamic Processor Selector
                  Text(
                    'PAYMENT PROCESSOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (availableGateways.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No payment processors are currently active.',
                        style: TextStyle(color: colorScheme.error, fontSize: 13),
                      ),
                    )
                  else
                    Row(
                      children: availableGateways.map((gw) {
                        final id = (gw['id'] ?? '').toString();
                        final title = (gw['title'] ?? gw['name'] ?? id).toString();
                        final tagline = (gw['tagline'] ?? gw['description'] ?? '').toString();
                        final badge = (gw['badge'] ?? (id == 'bach' ? 'FAST' : null))?.toString();
                        final isSelected = selectedGateway == id;
                        final gwColor = _getGatewayColor(id);
                        final assetIcon = _getGatewayAsset(id);
                        final icon = _getGatewayIcon(id);

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: gw == availableGateways.last ? 0 : 10),
                            child: InkWell(
                              onTap: () => setModalState(() => selectedGateway = id),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? gwColor.withValues(alpha: 0.08)
                                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? gwColor : colorScheme.outlineVariant,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (assetIcon != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.asset(
                                              assetIcon,
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.contain,
                                            ),
                                          )
                                        else
                                          Icon(icon, size: 20, color: gwColor),
                                        if (badge != null && badge.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: gwColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              badge,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: gwColor,
                                              ),
                                            ),
                                          )
                                        else
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
                                            color: isSelected ? gwColor : colorScheme.outlineVariant,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tagline.isNotEmpty ? tagline : 'Instant Pay',
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),

                  // Amount quick select
                  Text(
                    'SELECT AMOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1000, 2000, 5000, 10000, 20000].map((amount) {
                      final isSelected = selectedAmount == amount && customAmountCtrl.text.isEmpty;
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedAmount = amount;
                            customAmountCtrl.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : colorScheme.outlineVariant,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '₦${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Custom amount field
                  Text(
                    'OR ENTER CUSTOM AMOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customAmountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. 15000',
                      prefixText: '₦ ',
                      prefixStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: selectedGateway == 'bach' ? const Color(0xFF10B981) : AppColors.primary,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: selectedGateway == 'bach' ? const Color(0xFF10B981) : AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        if (val.trim().isNotEmpty) {
                          selectedAmount = 0;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 22),

                  // Action button
                  Builder(
                    builder: (_) {
                      final currentGw = availableGateways.firstWhere(
                        (g) => g['id'] == selectedGateway,
                        orElse: () => {'id': selectedGateway, 'name': selectedGateway == 'bach' ? 'Bachs' : 'Paystack', 'title': selectedGateway == 'bach' ? 'Bachs' : 'Paystack'},
                      );
                      final currentGwTitle = (currentGw['title'] ?? currentGw['name'] ?? selectedGateway).toString();
                      final currentGwColor = _getGatewayColor(selectedGateway);
                      final currentGwIcon = _getGatewayIcon(selectedGateway);

                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: availableGateways.isEmpty ? null : () async {
                            final enteredAmt = int.tryParse(customAmountCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), ''));
                            final finalAmount = enteredAmt != null && enteredAmt > 0 ? enteredAmt : selectedAmount;
                            if (finalAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select or enter an amount to fund.')),
                              );
                              return;
                            }
                            Navigator.pop(modalContext);
                            await _fundAmount(finalAmount, colorScheme, gateway: selectedGateway);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentGwColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(currentGwIcon, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Proceed with $currentGwTitle$formattedAmount',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final balance = (_wallet?['balance'] ?? 0).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    final escrow = (_wallet?['escrow_balance'] ?? 0).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Wallet & Balance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: colorScheme.surface,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Wallet Card (Stitch Gen Z Redesign)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
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
                              const Text(
                                'AVAILABLE BALANCE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '₦$escrow in escrow',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '₦$balance',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showFundWallet(colorScheme),
                            icon: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF0E0F13)),
                            label: const Text(
                              'Add Money / Fund Wallet',
                              style: TextStyle(
                                color: Color(0xFF0E0F13),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0E0F13),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'TOTAL FUNDED',
                            value: '₦${(_wallet?['total_funded'] ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                            icon: Icons.trending_up_rounded,
                            color: AppColors.success,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'IN ESCROW',
                            value: '₦$escrow',
                            icon: Icons.shield_rounded,
                            color: AppColors.primary,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Transaction History Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${_transactions.length} items',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_transactions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 40, color: colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your funding history and errand payments will appear here.',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._transactions.map(
                        (tx) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TransactionItem(tx: tx, colorScheme: colorScheme),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
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

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: colorScheme.onSurface,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
    final txColor = isCredit ? AppColors.success : colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.success.withValues(alpha: 0.12)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.success : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? 'Transaction',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  tx['type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'PAYMENT',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : '-'}₦${(tx['amount'] ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: txColor,
            ),
          ),
        ],
      ),
    );
  }
}
