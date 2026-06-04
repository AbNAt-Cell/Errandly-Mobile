import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  Map<String, bool> _prefs = {};
  bool _loading = true;
  bool _saving = false;

  static const _labels = {
    'push_enabled': ('Push notifications', 'Master switch for all mobile alerts'),
    'errand_updates': ('Errand updates', 'Offers, assignments, and status changes'),
    'payments': ('Payments', 'Earnings released and wallet activity'),
    'account': ('Account', 'KYC results and account notices'),
    'marketing': ('Announcements', 'Promotions and platform news'),
    'alerts': ('Safety & disputes', 'Panic alerts and dispute updates'),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await getIt<ApiClient>().getNotificationPreferences();
      final raw = res.data['preferences'] as Map<String, dynamic>? ?? {};
      setState(() {
        _prefs = raw.map((k, v) => MapEntry(k, v == true));
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save(String key, bool value) async {
    setState(() {
      _prefs[key] = value;
      _saving = true;
    });

    try {
      final res = await getIt<ApiClient>().updateNotificationPreferences({key: value});
      final raw = res.data['preferences'] as Map<String, dynamic>? ?? {};
      setState(() {
        _prefs = raw.map((k, v) => MapEntry(k, v == true));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save preference.'), backgroundColor: AppColors.danger),
        );
      }
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notification settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(color: AppColors.primary),
                  ),
                const Text(
                  'Choose which push notifications you receive. In-app notifications always appear in your inbox.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ..._labels.entries.map((entry) {
                  final key = entry.key;
                  final (title, subtitle) = entry.value;
                  final enabled = _prefs[key] ?? true;
                  final isMaster = key == 'push_enabled';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      title: Text(title, style: TextStyle(fontWeight: isMaster ? FontWeight.w700 : FontWeight.w600)),
                      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                      value: enabled,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                      activeThumbColor: AppColors.primary,
                      onChanged: _saving
                          ? null
                          : (v) {
                              _save(key, v);
                              if (key == 'push_enabled' && !v) {
                                setState(() {
                                  for (final k in _prefs.keys) {
                                    if (k != 'push_enabled') {
                                      _prefs[k] = false;
                                    }
                                  }
                                });
                              }
                            },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
