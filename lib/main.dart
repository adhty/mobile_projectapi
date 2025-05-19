import 'package:flutter/material.dart';
import 'package:sisfo_sarpas/pages/home_pages.dart';
import 'package:sisfo_sarpas/pages/login_pages.dart';
import 'package:sisfo_sarpas/pages/pengembalian/pengembalian_pages.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Login',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/pengembalian': (context) => const PengembalianPage(),
      },
    );
  }
}
