import 'package:flutter/material.dart';
import 'package:sisfo_sarpas/pages/barang/barang_pages.dart';
import 'package:sisfo_sarpas/pages/peminjaman/peminjaman_pages.dart';
import 'package:sisfo_sarpas/pages/pengembalian/pengembalian_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    BarangPage(),
    PeminjamanPage(),
    PengembalianPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Biar bisa lebih dari 3 item
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_circle_down),
            label: 'Pinjam',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_circle_up),
            label: 'Kembalikan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
