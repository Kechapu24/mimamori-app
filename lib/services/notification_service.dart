import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// アプリ起動時に1回だけ呼ぶ
  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  /// 通知を表示する（第2段階で使う）
  static Future<void> showLowActivityNotification(int steps) async {
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
