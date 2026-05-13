import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('No conversations yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Messages appear when a runner is assigned to your errand', style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
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

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (otherParty?['first_name']?[0] ?? '?').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(
                        '${otherParty?['first_name'] ?? ''} ${otherParty?['last_name'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      subtitle: Text(
                        lastMsg?['content'] ?? conv['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      trailing: unread > 0
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            )
                          : null,
                      onTap: () => Navigator.pushNamed(context, '/customer/messages/${conv['errand_id']}'),
                    );
                  },
                ),
    );
  }
}
