import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key});

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  final _codeController = TextEditingController();

  String? _linkedParentId;
  bool _isLoadingLink = true;
  bool _isLinking = false;
  String? _linkError;

  @override
  void initState() {
    super.initState();
    _checkExistingLink();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// 自分がすでに親と紐づいているか確認する
  Future<void> _checkExistingLink() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!mounted) return;
    setState(() {
      _linkedParentId = snapshot.data()?['linkedParentId'];
      _isLoadingLink = false;
    });
  }

  /// 招待コードを検索し、見つかった親のuidを自分のドキュメントに保存する
  Future<void> _linkWithCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = _codeController.text.trim().toUpperCase();
    if (uid == null || code.isEmpty) return;

    setState(() {
      _isLinking = true;
      _linkError = null;
    });

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      setState(() {
        _isLinking = false;
        _linkError = 'コードが見つかりませんでした';
      });
      return;
    }

    final parentUid = result.docs.first.id;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'role': 'child',
      'linkedParentId': parentUid,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _linkedParentId = parentUid;
      _isLinking = false;
    });
  }

  /// 招待コード入力画面
  Widget _buildLinkForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('招待コードを入力', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '招待コード',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_linkError != null) ...[
            Text(_linkError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
          ],
          _isLinking
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _linkWithCode,
                  child: const Text('連携する'),
                ),
        ],
      ),
    );
  }

  /// 紐づけ済みの親の歩数をリアルタイム表示
  Widget _buildStepsView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_linkedParentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('エラーが発生しました: ${snapshot.error}');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('家族の今日の歩数', style: TextStyle(fontSize: 20)),
              SizedBox(height: 16),
              Text('---- 歩', style: TextStyle(fontSize: 48)),
              SizedBox(height: 32),
              Text('状態：親のデータが見つかりません', style: TextStyle(fontSize: 18)),
            ],
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final steps = data['steps'] ?? 0;

        // 最終更新時刻を整形（未保存の場合は null のまま）
        final Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
        final String updatedAtText = updatedAt == null
            ? '---'
            : '${updatedAt.toDate().hour.toString().padLeft(2, '0')}:'
                  '${updatedAt.toDate().minute.toString().padLeft(2, '0')}';

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('家族の今日の歩数', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Text('$steps 歩', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 32),
            Text(
              '最終更新：$updatedAtText',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('状態：取得済み', style: TextStyle(fontSize: 18)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('子ホーム')),
      body: Center(
        child: _isLoadingLink
            ? const CircularProgressIndicator()
            : _linkedParentId == null
            ? _buildLinkForm()
            : _buildStepsView(),
      ),
    );
  }
}
