import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class RunnerMessagesScreen extends StatefulWidget {
  const RunnerMessagesScreen({super.key});

  @override
  State<RunnerMessagesScreen> createState() => _RunnerMessagesScreenState();
}

class _RunnerMessagesScreenState extends State<RunnerMessagesScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = getIt<ApiClient>();
      final res = await api.getConversations();
      setState(() {
        _conversations = res.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.runnerBackground,
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.runnerTextMuted),
                      SizedBox(height: 12),
                      Text('No conversations yet', style: TextStyle(color: AppColors.runnerTextMuted, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conversations.length,
                  itemBuilder: (_, i) {
                    final conv = _conversations[i];
                    final otherParty = conv['other_party'];
                    final lastMsg = conv['last_message'];
                    final unread = conv['unread_count'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.runnerSurface, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 22,
                            child: Text(
                              (otherParty?['first_name']?[0] ?? '?').toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${otherParty?['first_name'] ?? ''} ${otherParty?['last_name'] ?? ''}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                Text(lastMsg?['content'] ?? conv['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.runnerTextMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
