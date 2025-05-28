import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pengembalian_service.dart';
import '../peminjaman/peminjaman_model.dart';
import 'riwayat_pengembalian_page.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({super.key});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  final PengembalianService _service = PengembalianService();
  bool _isLoading = true;
  List<Peminjaman> _peminjamanAktif = [];

  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _jumlahKembaliController = TextEditingController();
  final TextEditingController _tanggalPengembalianController = TextEditingController();

  // Ubah nilai kondisi barang sesuai dengan yang diharapkan backend (lowercase)
  String _kondisiBarang = 'baik';
  final List<String> _kondisiOptions = ['baik', 'rusak', 'hilang'];

  @override
  void initState() {
    super.initState();
    _loadPeminjamanAktif();
    // Set tanggal hari ini sebagai default
    _tanggalPengembalianController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _loadPeminjamanAktif() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final peminjamanAktif = await _service.fetchPeminjamanAktif();

      // Update nama barang
      await _service.updateBarangNames(peminjamanAktif);

      setState(() {
        _peminjamanAktif = peminjamanAktif;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data peminjaman aktif: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow dates up to a year from now
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalPengembalianController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _showKembalikanDialog(Peminjaman peminjaman) async {
    _resetForm();
    _jumlahKembaliController.text = peminjaman.jumlah.toString();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kembalikan ${peminjaman.namaBarang}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jumlah Dipinjam: ${peminjaman.jumlah}'),
                Text('Tanggal Pinjam: ${peminjaman.tglPinjam}'),
                const SizedBox(height: 16),

                const SizedBox(height: 16),
                TextField(
                  controller: _jumlahKembaliController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Dikembalikan',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _tanggalPengembalianController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Pengembalian',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                ),

                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _kondisiBarang,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi Barang',
                    border: OutlineInputBorder(),
                  ),
                  items: _kondisiOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.substring(0, 1).toUpperCase() + value.substring(1)), // Capitalize first letter for display
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _kondisiBarang = newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Kembalikan'),
              onPressed: () {
                _kembalikanBarang(peminjaman);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    _catatanController.clear();
    _jumlahKembaliController.clear();
    _tanggalPengembalianController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _kondisiBarang = 'baik'; // Ubah ke nilai yang benar (lowercase)
  }

  Future<void> _kembalikanBarang(Peminjaman peminjaman) async {
    final jumlahKembali = int.tryParse(_jumlahKembaliController.text);
    if (jumlahKembali == null || jumlahKembali <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah kembali harus berupa angka positif')),
      );
      return;
    }

    if (jumlahKembali > peminjaman.jumlah) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah kembali tidak boleh melebihi jumlah pinjam')),
      );
      return;
    }

    // Tampilkan loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    final data = {
      'peminjaman_id': peminjaman.id,
      'tanggal_pengembalian': _tanggalPengembalianController.text,
      'kondisi_barang': _kondisiBarang,
      'catatan': _catatanController.text,
      'status': 'menunggu',
      'jumlah_kembali': jumlahKembali,
      // biaya_denda akan dihitung oleh backend
    };

    try {
      final success = await _service.kembalikanBarang(data);

      // Tutup loading indicator
      Navigator.of(context).pop();

      if (success) {
        // Update status pengembalian
        setState(() {
          peminjaman.sudahDikembalikan = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil mengajukan pengembalian barang'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPeminjamanAktif(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengajukan pengembalian barang. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Tutup loading indicator
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengembalian Barang'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiwayatPengembalianPage(),
                ),
              );
            },
            tooltip: 'Lihat Riwayat Pengembalian',
          ),
        ],
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
              child: _peminjamanAktif.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada peminjaman aktif',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _peminjamanAktif.length,
                      itemBuilder: (context, index) {
                        final peminjaman = _peminjamanAktif[index];
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
                                Text(
                                  peminjaman.namaBarang != 'Barang tidak diketahui'
                                      ? peminjaman.namaBarang
                                      : 'Barang ID: ${peminjaman.idBarang}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Jumlah: ${peminjaman.jumlah}'),
                                Text('Tanggal Pinjam: ${peminjaman.tglPinjam}'),
                                Text('Alasan: ${peminjaman.alasanPinjam}'),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!peminjaman.sudahDikembalikan)
                                      ElevatedButton.icon(
                                        onPressed: () => _showKembalikanDialog(peminjaman),
                                        icon: const Icon(Icons.assignment_return),
                                        label: const Text('Kembalikan'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                      )
                                    else
                                      Chip(
                                        label: const Text('Sudah Dikembalikan'),
                                        backgroundColor: Colors.green.shade100,
                                        labelStyle: TextStyle(color: Colors.green.shade800),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPeminjamanAktif,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _jumlahKembaliController.dispose();
    _tanggalPengembalianController.dispose();
    super.dispose();
  }
}
























