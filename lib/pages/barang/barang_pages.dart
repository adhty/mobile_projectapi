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

  @override
  void initState() {
    super.initState();
    _futureBarang = _barangService.fetchBarang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Barang')),
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
            final barangList = snapshot.data!;
            return ListView.builder(
              itemCount: barangList.length,
              itemBuilder: (context, index) {
                final barang = barangList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      // Navigasi ke halaman detail barang
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BarangDetailPage(barang: barang),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: barang.foto.isNotEmpty
                          ? Image.network(
                              'http://127.0.0.1:8000/storage/${barang.foto}',
                              width: 50,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                            )
                          : const Icon(Icons.image_not_supported),
                      title: Text(barang.nama),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stok: ${barang.jumlahBarang}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
