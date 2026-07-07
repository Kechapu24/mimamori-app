import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //　入力内容を受けるコントローラー
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  //　ローディング中かのフラグ
  bool _isLoading = false;

  //　ログイン処理
  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // ログインの成功　→　次の画面へ（後で追加）
      print('ログイン成功！');
    } on FirebaseAuthException catch (e) {
      // エラーメッセージを日本語で表示
      String message = 'ログインに失敗しました';
      if (e.code == 'user-not-found') message = 'メールアドレスが見つかりません';
      if (e.code == 'wrong-password') message = 'パスワードが間違っています';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'パスワード',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            //　ローディング中にはぐるぐる、それ以外はボタンを表示
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text('ログイン')),
          ],
        ),
      ),
    );
  }
}
