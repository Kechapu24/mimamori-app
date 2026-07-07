import 'package:flutter/material.dart';

class ChildHomePage extends StatelessWidget {
  const ChildHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('子ホーム')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('家族の今日の歩数', style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            Text('---- 歩', style: TextStyle(fontSize: 48)),
            SizedBox(height: 32),
            Text('状態：確認中...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
