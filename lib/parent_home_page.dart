import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  final _stepsController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveSteps() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'role': 'parent',
      'steps': int.tryParse(_stepsController.text) ?? 0,
    }, SetOptions(merge: true));

    setState(() => _isSaving = false);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('歩数を保存しました')));
    }
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
            const Text('今日の歩数を入力', style: TextStyle(fontSize: 20)),
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
