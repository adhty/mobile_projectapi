import 'package:flutter/material.dart';
import 'package:sisfo_sarpas/pages/home_pages.dart';
import 'package:sisfo_sarpas/pages/login_pages.dart';
import 'package:sisfo_sarpas/pages/profil/profil_page.dart';

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
      home: const LoginPage(), // Definisikan home
      routes: {
        
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilPage(),
      },
      
    );
  }
}
