import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'parent_home_page.dart';
import 'child_home_page.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  // ログアウト処理
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // main.dart の StreamBuilder がログイン状態の変化を検知し、
    // 自動的にログイン画面へ切り替わります
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('役割を選択'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('あなたはどちらですか？', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParentHomePage(),
                  ),
                );
              },
              child: const Text('見守られる（親）'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChildHomePage(),
                  ),
                );
              },
              child: const Text('見守る（子）'),
            ),
          ],
        ),
      ),
    );
  }
}