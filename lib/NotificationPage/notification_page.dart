import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String body;
  final DateTime receivedAt;

  NotificationItem({
    required this.title,
    required this.body,
    required this.receivedAt,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // ダミーデータ（FCM実装後は実際の通知に差し替え）
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: '🎉 今日も元気に歩けました！',
      body: '8000歩達成しました✨',
      receivedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationItem(
      title: '活動量のお知らせ',
      body: '今日の活動量が少なめです（320歩）',
      receivedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お知らせ')),
      body: _notifications.isEmpty
          ? const Center(child: Text('お知らせはありません'))
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.notifications, color: Colors.green),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item.body),
                  trailing: Text(
                    _formatTime(item.receivedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}
