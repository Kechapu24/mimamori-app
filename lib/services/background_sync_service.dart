import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

const taskName = 'mimamori_hourly_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskName) {
      await BackgroundSyncService.syncStepsToFirestore();
    }
    return Future.value(true);
  });
}

class BackgroundSyncService {
  static final _health = Health();

  static Future<void> registerPeriodicSync() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // ← trueに変更（ログが出るようになる）
    );

    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace, // ← keepからreplaceに変更
    );

    print('WorkManager: タスク登録完了 - $taskName'); // ← 追加
  }

  static Future<int?> syncStepsToFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) return null;

      final requested = await _health.requestAuthorization([
        HealthDataType.STEPS,
      ]);
      if (!requested) return null;

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      if (steps == null) return null;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'steps': steps,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return steps;
    } catch (e) {
      return null;
    }
  }
}
