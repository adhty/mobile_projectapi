import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pengembalian_model.dart';
import 'pengembalian_service.dart';

class RiwayatPengembalianPage extends StatefulWidget {
  const RiwayatPengembalianPage({super.key});

  @override
  State<RiwayatPengembalianPage> createState() => _RiwayatPengembalianPageState();
}

class _RiwayatPengembalianPageState extends State<RiwayatPengembalianPage> {
  final PengembalianService _service = PengembalianService();
  bool _isLoading = true;
  List<Pengembalian> _riwayatPengembalian = [];

  @override
  void initState() {
    super.initState();
    _loadRiwayatPengembalian();
  }

  Future<void> _loadRiwayatPengembalian() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final riwayat = await _service.fetchRiwayatPengembalian();
      setState(() {
        _riwayatPengembalian = riwayat;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat pengembalian: $e')),
        );
      }
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return 'green';
      case 'ditolak':
        return 'red';
      case 'menunggu':
        return 'orange';
      default:
        return 'blue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pengembalian'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: _riwayatPengembalian.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada riwayat pengembalian',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _riwayatPengembalian.length,
                      itemBuilder: (context, index) {
                        final pengembalian = _riwayatPengembalian[index];
                        final statusColor = _getStatusColor(pengembalian.status);

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pengembalian.namaBarang,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor == 'green'
                                            ? Colors.green
                                            : statusColor == 'red'
                                                ? Colors.red
                                                : statusColor == 'orange'
                                                    ? Colors.orange
                                                    : Colors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        pengembalian.status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Tanggal Pengembalian: ${pengembalian.tanggalPengembalian}'),
                                Text('Kondisi Barang: ${pengembalian.kondisiBarang.substring(0, 1).toUpperCase() + pengembalian.kondisiBarang.substring(1)}'),
                                Text('Jumlah Dikembalikan: ${pengembalian.jumlahKembali}'),
                                if (pengembalian.biayaDenda != null && pengembalian.biayaDenda! > 0)
                                  Text(
                                    'Biaya Denda: Rp ${NumberFormat('#,###').format(pengembalian.biayaDenda)}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (pengembalian.catatan != null && pengembalian.catatan!.isNotEmpty)
                                  Text('Catatan: ${pengembalian.catatan}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRiwayatPengembalian,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

