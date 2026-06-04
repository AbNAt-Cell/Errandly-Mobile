import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class CustomerAssistantScreen extends StatefulWidget {
  const CustomerAssistantScreen({super.key});

  @override
  State<CustomerAssistantScreen> createState() => _CustomerAssistantScreenState();
}

class _CustomerAssistantScreenState extends State<CustomerAssistantScreen> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String? _sessionId;
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
      _controller.clear();
    });
    try {
      final res = await getIt<ApiClient>().aiChat({
        'message': text,
        if (_sessionId != null) 'session_id': _sessionId,
      });
      final data = res.data;
      setState(() {
        _sessionId = data['session_id']?.toString();
        _messages.add({'role': 'assistant', 'text': data['reply']?.toString() ?? 'No response'});
      });
    } catch (e) {
      setState(() => _messages.add({'role': 'assistant', 'text': 'Sorry, the assistant is unavailable.'}));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Errandly Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: isUser ? null : Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      m['text'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: AppColors.primary),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Ask about errands, escrow, policies…'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(onPressed: _loading ? null : _send, icon: const Icon(Icons.send_rounded, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
