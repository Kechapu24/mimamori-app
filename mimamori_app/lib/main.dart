import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '見守りアプリ',
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const LoginPage(),
    );
  }
}
