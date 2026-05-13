import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../main.dart';
import 'runner_errand_detail_screen.dart';

class RunnerActivityScreen extends StatefulWidget {
  const RunnerActivityScreen({super.key});

  @override
  State<RunnerActivityScreen> createState() => _RunnerActivityScreenState();
}

class _RunnerActivityScreenState extends State<RunnerActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _errands = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) _load(); });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();
      String? status = switch (_tabController.index) {
        1 => 'completed',
        2 => 'cancelled',
        _ => null,
      };
      final res = await api.getMyErrands(params: status != null ? {'status': status} : null);
      setState(() {
        _errands = res.data['data'] ?? [];
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
      backgroundColor: AppColors.runnerBackground,
      appBar: AppBar(
        title: const Text('Activity'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.runnerTextMuted,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'All'), Tab(text: 'Completed'), Tab(text: 'Cancelled')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.runnerSurface,
              onRefresh: _load,
              child: _errands.isEmpty
                  ? const Center(child: Text('No errands found', style: TextStyle(color: AppColors.runnerTextMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _errands.length,
                      itemBuilder: (_, i) {
                        final errand = _errands[i];
                        final status = errand['status'] ?? '';
                        final isCompleted = status == 'completed';

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RunnerErrandDetailScreen(errandId: errand['id']))),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.runnerSurface, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: (isCompleted ? AppColors.success : AppColors.danger).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(child: Text(AppConstants.categoryEmojis[errand['category']] ?? '✨', style: const TextStyle(fontSize: 20))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(errand['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(AppConstants.statusLabels[status] ?? status, style: TextStyle(color: isCompleted ? AppColors.success : AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₦${errand['runner_earnings'] ?? 0}', style: TextStyle(color: isCompleted ? AppColors.success : AppColors.runnerTextMuted, fontWeight: FontWeight.w800, fontSize: 15)),
                                    const Icon(Icons.chevron_right_rounded, color: AppColors.runnerTextMuted, size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
