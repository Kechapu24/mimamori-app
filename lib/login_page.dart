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
      if (e.code == 'invalid-credential') message = 'メールアドレスまたはパスワードが間違っています';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //　新規登録処理
  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // 登録成功　→　次の画面へ（後で追加）
      print('新規登録成功！');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('新規登録が完了しました')));
      }
    } on FirebaseAuthException catch (e) {
      // エラーメッセージを日本語で表示
      String message = '新規登録に失敗しました';
      if (e.code == 'email-already-in-use') message = 'このメールアドレスは既に使われています';
      if (e.code == 'weak-password') message = 'パスワードは6文字以上にしてください';
      if (e.code == 'invalid-email') message = 'メールアドレスの形式が正しくありません';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text('ログイン'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _signUp,
                        child: const Text('新規登録はこちら'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
