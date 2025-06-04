import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pengembalian/pengembalian_model.dart';
import '../pengembalian/pengembalian_service.dart';

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
      print('Error dalam _loadRiwayatPengembalian: $e');
      setState(() {
        _riwayatPengembalian = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal memuat riwayat pengembalian. Silakan coba lagi nanti.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Coba Lagi',
              onPressed: _loadRiwayatPengembalian,
              textColor: Colors.white,
            ),
          ),
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
                        final Color badgeColor = statusColor == 'green'
                            ? Colors.green.shade600
                            : statusColor == 'red'
                                ? Colors.red.shade600
                                : statusColor == 'orange'
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade600;

                        String formattedDate = '';
                        try {
                          final dt = DateTime.parse(pengembalian.tanggalPengembalian);
                          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
                        } catch (_) {
                          formattedDate = pengembalian.tanggalPengembalian;
                        }

                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor: Colors.blue.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: nama barang + status badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pengembalian.namaBarang,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: badgeColor.withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        pengembalian.status.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Info rows dengan icon
                                _infoRow(Icons.calendar_today, 'Tanggal Pengembalian', formattedDate),
                                _infoRow(
                                  Icons.info_outline,
                                  'Kondisi Barang',
                                  pengembalian.kondisiBarang[0].toUpperCase() +
                                      pengembalian.kondisiBarang.substring(1),
                                ),
                                _infoRow(Icons.confirmation_number, 'Jumlah Dikembalikan',
                                    '${pengembalian.jumlahKembali}'),
                                if (pengembalian.biayaDenda != null && pengembalian.biayaDenda! > 0)
                                  _infoRow(
                                    Icons.money_off,
                                    'Biaya Denda',
                                    'Rp ${NumberFormat('#,###').format(pengembalian.biayaDenda)}',
                                    valueColor: Colors.red.shade700,
                                    iconColor: Colors.red.shade700,
                                  ),
                                if (pengembalian.catatan != null && pengembalian.catatan!.isNotEmpty)
                                  _infoRow(Icons.note, 'Catatan', pengembalian.catatan!),
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
        tooltip: 'Muat Ulang Riwayat',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color valueColor = Colors.black87, Color iconColor = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
