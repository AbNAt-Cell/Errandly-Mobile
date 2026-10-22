import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../shared/presentation/screens/voice_call_screen.dart';

class CustomerMessageThreadScreen extends StatefulWidget {
  final String publicId;

  const CustomerMessageThreadScreen({super.key, required this.publicId});

  @override
  State<CustomerMessageThreadScreen> createState() => _CustomerMessageThreadScreenState();
}

class _CustomerMessageThreadScreenState extends State<CustomerMessageThreadScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadSilent());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await getIt<ApiClient>().getMessages(widget.publicId);
      if (mounted) {
        setState(() {
          _messages = res.data['data'] ?? res.data ?? [];
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSilent() async {
    try {
      final res = await getIt<ApiClient>().getMessages(widget.publicId);
      final list = res.data['data'] ?? res.data ?? [];
      if (mounted && list.length != _messages.length) {
        setState(() {
          _messages = list;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await getIt<ApiClient>().sendMessage(widget.publicId, {'content': text, 'type': 'text'});
      _controller.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Real-time updates', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF10B981)),
            tooltip: 'Voice Call',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VoiceCallScreen(
                    errandId: widget.publicId,
                    errandTitle: 'Errand Chat',
                    contactName: 'Errand Contact',
                    isIncoming: false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMine = msg['is_mine'] == true;
                          final type = msg['type']?.toString() ?? 'text';
                          final mediaUrl = msg['media_url']?.toString();
                          final duration = msg['duration_seconds'] ?? 0;
                          final isSystem = type == 'system' || msg['is_system'] == true;

                          if (isSystem) {
                            return Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Text(
                                  msg['content']?.toString() ?? '📞 Voice Call',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                              decoration: BoxDecoration(
                                color: isMine ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: isMine ? null : Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image message
                                  if (type == 'image' && mediaUrl != null) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        mediaUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 40),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],

                                  // Video message
                                  if (type == 'video' && mediaUrl != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Video Clip',
                                            style: TextStyle(
                                              color: isMine ? Colors.white : AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],

                                  // Voice note message
                                  if (type == 'voice' && mediaUrl != null) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.mic_rounded,
                                          color: isMine ? Colors.white : AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Voice Note (${duration}s)',
                                          style: TextStyle(
                                            color: isMine ? Colors.white : AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],

                                  // Text content
                                  if (msg['content'] != null && msg['content'].toString().isNotEmpty)
                                    Text(
                                      msg['content'].toString(),
                                      style: TextStyle(
                                        color: isMine ? Colors.white : AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
