import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// アプリ起動時に1回だけ呼ぶ
  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  /// 21時以降かつ500歩未満なら通知を出す
  static Future<void> checkAndNotify() async {
    final now = DateTime.now();

    // 21時未満なら何もしない
    if (now.hour < 21) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Firestoreから歩数を取得
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final steps = doc.data()?['steps'] as int?;
    if (steps == null) return;

    // 500歩未満なら通知
    if (steps < 500) {
      await _showLowActivityNotification(steps);
    }
  }

  static Future<void> _showLowActivityNotification(int steps) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'low_activity',
        '活動量アラート',
        channelDescription: '活動量が少ないときに通知します',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(0, '見守りアラート', '今日の歩数が${steps}歩です。活動量が少なめです。', details);
  }
}
