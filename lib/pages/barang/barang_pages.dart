import 'package:flutter/material.dart';
import 'barang_model.dart';
import 'barang_service.dart';
import 'barang_detail_page.dart';

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  late Future<List<Barang>> _futureBarang;
  final BarangService _barangService = BarangService();

  List<Barang> _allBarang = [];
  List<Barang> _filteredBarang = [];

  String _searchQuery = '';
  String _stokFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _futureBarang = _barangService.fetchBarang();
    _futureBarang.then((barangList) {
      setState(() {
        _allBarang = barangList;
        _filteredBarang = barangList;
      });
    });
  }

  void _filterBarang() {
    setState(() {
      _filteredBarang = _allBarang.where((barang) {
        final matchNama = barang.nama.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchStok = _stokFilter == 'Semua'
            ? true
            : _stokFilter == 'Tersedia'
                ? barang.jumlahBarang > 0
                : barang.jumlahBarang == 0;
        return matchNama && matchStok;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Barang'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Barang>>(
        future: _futureBarang,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada barang'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // 🔍 Search Bar
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Cari barang...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterBarang();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🧮 Filter stok
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Filter Stok: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _stokFilter,
                        items: const [
                          DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                          DropdownMenuItem(value: 'Tersedia', child: Text('Tersedia')),
                          DropdownMenuItem(value: 'Habis', child: Text('Habis')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _stokFilter = value;
                            _filterBarang();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 🧱 Grid Barang
                  Expanded(
                    child: _filteredBarang.isEmpty
                        ? const Center(child: Text('Barang tidak ditemukan'))
                        : GridView.builder(
                            itemCount: _filteredBarang.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3 / 4,
                            ),
                            itemBuilder: (context, index) {
                              final barang = _filteredBarang[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BarangDetailPage(barang: barang),
                                    ),
                                  );
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: barang.foto.isNotEmpty
                                              ? Image.network(
                                                  'http://127.0.0.1:8000/storage/${barang.foto}',
                                                  height: 100,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.broken_image, size: 60),
                                                )
                                              : const Icon(Icons.image_not_supported, size: 60),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          barang.nama,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stok: ${barang.jumlahBarang}',
                                          style: TextStyle(
                                            color: barang.jumlahBarang > 0
                                                ? Colors.teal
                                                : Colors.redAccent,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
