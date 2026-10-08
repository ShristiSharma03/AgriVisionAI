import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  late Future<List<NotificationRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _notificationService.getNotificationHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _notificationService.getNotificationHistory();
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('notifications_clear_confirm_title')),
        content: Text(context.tr('notifications_clear_confirm_body')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('clear'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _notificationService.clearNotificationHistory();
    await _refresh();
  }

  Future<void> _deleteOne(NotificationRecord record) async {
    await _notificationService.deleteNotification(record.timestamp);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notifications_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: context.tr('clear_all'),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<NotificationRecord>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.notifications_none, size: 40, color: AppColors.greenAccent),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('notifications_empty'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = history[index];
                return Dismissible(
                  // A DateTime's microsecond-precision toString is unique
                  // enough within this list to safely key each item.
                  key: ValueKey(record.timestamp.toIso8601String()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  ),
                  onDismissed: (_) => _deleteOne(record),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.greenLightBg,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.notifications_outlined, color: AppColors.greenMid, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      record.title,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(record.timeAgo, style: theme.textTheme.bodySmall?.copyWith(fontSize: 8.5)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(record.body, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10, height: 1.4)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _deleteOne(record),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.close, size: 15, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}