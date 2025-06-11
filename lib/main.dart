import 'package:flutter/material.dart';
import 'package:sisfo_sarpas/pages/home_pages.dart';
import 'package:sisfo_sarpas/pages/login_pages.dart';
import 'package:sisfo_sarpas/pages/profil/profil_page.dart';
import 'package:sisfo_sarpas/pages/riwayat/riwayat_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Informasi Sarana Prasarana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
          primary: Colors.blue.shade700,
          secondary: Colors.orange,
        ),
        fontFamily: 'Poppins',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const LoginPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilPage(),
        '/riwayat': (context) => const RiwayatPage(),
      },
    );
  }
}
