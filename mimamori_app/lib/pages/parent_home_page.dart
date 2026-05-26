import 'package:flutter/material.dart';

class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('親ホーム')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('今日の歩数', style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            Text('---- 歩', style: TextStyle(fontSize: 48)),
            SizedBox(height: 32),
            Text('招待コード', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text('------', style: TextStyle(fontSize: 32)),
          ],
        ),
      ),
    );
  }
}
