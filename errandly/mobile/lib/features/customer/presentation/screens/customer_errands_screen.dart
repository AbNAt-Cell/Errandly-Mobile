import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../main.dart';
import 'errand_detail_screen.dart';

class CustomerErrandsScreen extends StatefulWidget {
  const CustomerErrandsScreen({super.key});

  @override
  State<CustomerErrandsScreen> createState() => _CustomerErrandsScreenState();
}

class _CustomerErrandsScreenState extends State<CustomerErrandsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _errands = [];
  bool _loading = true;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _status = switch (_tabController.index) {
          1 => 'pending_assignment,accepted,runner_en_route,in_progress',
          2 => 'completed',
          3 => 'cancelled,disputed',
          _ => '',
        };
      });
      _loadErrands();
    });
    _loadErrands();
  }

  Future<void> _loadErrands() async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();
      final params = _status.isNotEmpty ? {'status': _status} : null;
      final response = await api.getCustomerErrands(params: params);
      setState(() {
        _errands = response.data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Errands'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'All'), Tab(text: 'Active'), Tab(text: 'Done'), Tab(text: 'Issues')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadErrands,
              child: _errands.isEmpty
                  ? const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('No errands yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                      ],
                    ))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _errands.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ErrandListItem(errand: _errands[i]),
                    ),
            ),
    );
  }
}

class _ErrandListItem extends StatelessWidget {
  final Map<String, dynamic> errand;
  const _ErrandListItem({required this.errand});

  Color _statusColor(String status) {
    return switch (status) {
      'completed' => AppColors.success,
      'cancelled' || 'failed' => AppColors.danger,
      'disputed' => AppColors.warning,
      'awaiting_confirmation' => AppColors.info,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = errand['status'] ?? '';
    final statusLabel = AppConstants.statusLabels[status] ?? status;
    final category = errand['category'] ?? 'custom_errand';
    final emoji = AppConstants.categoryEmojis[category] ?? '✨';
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ErrandDetailScreen(errandId: errand['id']))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errand['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₦${errand['budget'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
