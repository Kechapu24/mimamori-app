import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/invite_code_generator.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  final _stepsController = TextEditingController();
  bool _isSaving = false;
  bool _isSyncing = false;
  String? _syncError;

  String? _inviteCode;
  bool _isLoadingCode = true;

  final _health = Health();

  @override
  void initState() {
    super.initState();
    _ensureInviteCode();
    _health.configure();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  /// 招待コードが未発行なら生成、発行済みなら取得する
  Future<void> _ensureInviteCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final snapshot = await userRef.get();

    if (snapshot.exists && snapshot.data()?['inviteCode'] != null) {
      // 既にコードがある場合はそれを使う
      setState(() {
        _inviteCode = snapshot.data()!['inviteCode'];
        _isLoadingCode = false;
      });
      return;
    }

    // 未発行の場合、重複しないコードを生成して保存
    final newCode = await _generateUniqueCode();
    await userRef.set({
      'role': 'parent',
      'inviteCode': newCode,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _inviteCode = newCode;
      _isLoadingCode = false;
    });
  }

  /// Firestore上で重複していないコードになるまで再生成
  Future<String> _generateUniqueCode() async {
    while (true) {
      final code = InviteCodeGenerator.generate();
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return code;
    }
  }

  Future<void> _saveSteps() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'role': 'parent',
      'steps': int.tryParse(_stepsController.text) ?? 0,
      'updatedAt': FieldValue.serverTimestamp(), // リアルタイム検証
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('歩数を保存しました')));
    }
  }

  Widget _buildInviteCodeCard() {
    if (_isLoadingCode) {
      return const CircularProgressIndicator();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('招待コード', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(
              _inviteCode ?? '---',
              style: const TextStyle(fontSize: 24, letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            const Text('このコードを子デバイスに入力してください', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
  // ...(_ensureInviteCode, _generateUniqueCode, _saveSteps, _buildInviteCodeCard は変更なしなので省略)

  /// Health Connectから今日の歩数を取得し、入力欄に反映する
  Future<void> _syncFromHealthConnect() async {
    setState(() {
      _isSyncing = true;
      _syncError = null;
    });

    try {
      // Android: 歩数取得に必要な Activity Recognition 権限をリクエスト
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) {
        setState(() {
          _isSyncing = false;
          _syncError = '活動認識の権限が許可されませんでした';
        });
        return;
      }

      // Health Connectへのアクセス権限をリクエスト
      final types = [HealthDataType.STEPS];
      final requested = await _health.requestAuthorization(types);

      if (!requested) {
        setState(() {
          _isSyncing = false;
          _syncError = 'Health Connectへのアクセスが許可されませんでした';
        });
        return;
      }

      // 今日の0時から現在までの歩数を取得
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(midnight, now);

      if (!mounted) return;

      if (steps == null) {
        setState(() {
          _isSyncing = false;
          _syncError = '歩数データが取得できませんでした';
        });
        return;
      }

      setState(() {
        _stepsController.text = steps.toString();
        _isSyncing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _syncError = 'エラーが発生しました: $e';
      });
    }
  }

  bool _isWritingTestData = false;
  String? _writeTestDataMessage;

  /// 【開発用】Health Connectにテスト用の歩数データを書き込む
  Future<void> _writeTestStepData() async {
    setState(() {
      _isWritingTestData = true;
      _writeTestDataMessage = null;
    });

    try {
      // 書き込み権限をリクエスト（読み取りとは別に必要）
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.WRITE];
      final requested = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (!requested) {
        setState(() {
          _isWritingTestData = false;
          _writeTestDataMessage = '書き込み権限が許可されませんでした';
        });
        return;
      }

      // 今日の0時から1時間分、5000歩のテストデータを書き込む
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final oneHourLater = midnight.add(const Duration(hours: 1));

      final success = await _health.writeHealthData(
        value: 5000,
        type: HealthDataType.STEPS,
        startTime: midnight,
        endTime: oneHourLater,
      );

      if (!mounted) return;

      setState(() {
        _isWritingTestData = false;
        _writeTestDataMessage = success
            ? 'テストデータ（5000歩）を書き込みました'
            : '書き込みに失敗しました';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWritingTestData = false;
        _writeTestDataMessage = 'エラーが発生しました: $e';
      });
    }
  }

  Widget _buildTestDataButton() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _isWritingTestData ? null : _writeTestStepData,
          icon: _isWritingTestData
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.science_outlined, size: 18),
          label: Text(
            _isWritingTestData ? '書き込み中...' : '【開発用】テスト歩数を書き込む',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        if (_writeTestDataMessage != null)
          Text(
            _writeTestDataMessage!,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildSyncButton() {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _isSyncing ? null : _syncFromHealthConnect,
          icon: _isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(_isSyncing ? '同期中...' : 'Health Connectと同期'),
        ),
        if (_syncError != null) ...[
          const SizedBox(height: 8),
          Text(
            _syncError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('親ホーム')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInviteCodeCard(),
            const SizedBox(height: 32),
            const Text('今日の歩数を入力', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            _buildSyncButton(),
            const SizedBox(height: 8),
            _buildTestDataButton(), // テストボタンの呼び出し
            const SizedBox(height: 16),
            TextField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '歩数',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveSteps,
                    child: const Text('保存する'),
                  ),
          ],
        ),
      ),
    );
  }
}
