import 'package:flutter/material.dart';
import 'package:sisfo_sarpas/pages/barang/barang_pages.dart';
import 'package:sisfo_sarpas/pages/peminjaman/peminjaman_pages.dart';
import 'package:sisfo_sarpas/pages/pengembalian/pengembalian_pages.dart';
import 'package:sisfo_sarpas/pages/riwayat/riwayat_enhanced_page.dart';
import 'package:sisfo_sarpas/pages/profil/profil_page.dart';

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
    RiwayatEnhancedPage(),
    ProfilPage(), // Tambahkan halaman profil
  ];

  static const List<String> _appBarTitles = [
    'Daftar Barang',
    'Peminjaman',
    'Pengembalian',
    'Riwayat',
    'Profil',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 4 ? null : AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Barang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_circle_down),
            label: 'Pinjam',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_circle_up),
            label: 'Kembali',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton(
              onPressed: () {
                // Navigasi ke halaman peminjaman
                setState(() {
                  _selectedIndex = 1; // Index 1 adalah halaman peminjaman
                });
              },
              backgroundColor: Colors.blue.shade700,
              tooltip: 'Pinjam Barang',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
