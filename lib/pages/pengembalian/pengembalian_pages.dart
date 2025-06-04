import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sisfo_sarpas/pages/riwayat/riwayat_pengembalian_page.dart';
import 'pengembalian_service.dart';
import '../peminjaman/peminjaman_model.dart';

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

  String _kondisiBarang = 'baik';
  final List<String> _kondisiOptions = ['baik', 'rusak', 'hilang'];

  @override
  void initState() {
    super.initState();
    _loadPeminjamanAktif();
    _tanggalPengembalianController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _loadPeminjamanAktif() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final peminjamanAktif = await _service.fetchPeminjamanAktif();
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    final textTheme = Theme.of(context).textTheme;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Kembalikan ${peminjaman.namaBarang}',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogInfoRow(Icons.inventory, 'Jumlah Dipinjam: ${peminjaman.jumlah}', textTheme),
                        _buildDialogInfoRow(Icons.calendar_today, 'Tanggal Pinjam: ${peminjaman.tglPinjam}', textTheme),
                      ],
                    ),
                  ),
                ),
                TextField(
                  controller: _jumlahKembaliController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Dikembalikan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _tanggalPengembalianController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Pengembalian',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: const Icon(Icons.event),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _kondisiBarang,
                  decoration: InputDecoration(
                    labelText: 'Kondisi Barang',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: _kondisiOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value[0].toUpperCase() + value.substring(1)),
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
                const SizedBox(height: 18),
                TextField(
                  controller: _catatanController,
                  decoration: InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade700)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
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
    _kondisiBarang = 'baik';
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    final data = {
      'peminjaman_id': peminjaman.id,
      'tanggal_pengembalian': _tanggalPengembalianController.text,
      'kondisi_barang': _kondisiBarang,
      'catatan': _catatanController.text,
      'status': 'menunggu',
      'jumlah_kembali': jumlahKembali,
    };

    try {
      final success = await _service.kembalikanBarang(data);
      Navigator.of(context).pop();

      if (success) {
        setState(() {
          peminjaman.sudahDikembalikan = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil mengajukan pengembalian barang'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPeminjamanAktif();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengajukan pengembalian barang. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengembalian Barang'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RiwayatPengembalianPage()),
              );
            },
            tooltip: 'Lihat Riwayat Pengembalian',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
              ),
              child: _peminjamanAktif.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, 
                               size: 64, 
                               color: colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada peminjaman aktif',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: colorScheme.primary,
                      onRefresh: _loadPeminjamanAktif,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: _peminjamanAktif.length,
                        itemBuilder: (context, index) {
                          final peminjaman = _peminjamanAktif[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: peminjaman.sudahDikembalikan
                                    ? colorScheme.tertiary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            color: peminjaman.sudahDikembalikan
                                ? colorScheme.tertiaryContainer
                                : colorScheme.surfaceContainerLow,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => !peminjaman.sudahDikembalikan
                                  ? _showKembalikanDialog(peminjaman)
                                  : null,
                              splashColor: peminjaman.sudahDikembalikan 
                                  ? Colors.transparent 
                                  : colorScheme.primary.withOpacity(0.1),
                              highlightColor: peminjaman.sudahDikembalikan 
                                  ? Colors.transparent 
                                  : colorScheme.primary.withOpacity(0.05),
                              child: Stack(
                                children: [
                                  if (peminjaman.sudahDikembalikan)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: colorScheme.tertiary),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.pending_actions, size: 16, color: colorScheme.tertiary),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Menunggu Persetujuan',
                                              style: textTheme.labelSmall?.copyWith(
                                                color: colorScheme.onTertiaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          peminjaman.namaBarang != 'Barang tidak diketahui'
                                              ? peminjaman.namaBarang
                                              : 'Barang ID: ${peminjaman.idBarang}',
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: peminjaman.sudahDikembalikan
                                                ? colorScheme.onTertiaryContainer
                                                : colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        _buildInfoRow(Icons.inventory, 'Jumlah: ${peminjaman.jumlah}', textTheme, colorScheme),
                                        _buildInfoRow(Icons.calendar_today, 'Tanggal Pinjam: ${peminjaman.tglPinjam}', textTheme, colorScheme),
                                        _buildInfoRow(Icons.notes, 'Alasan: ${peminjaman.alasanPinjam}', textTheme, colorScheme),
                                        const SizedBox(height: 18),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (!peminjaman.sudahDikembalikan)
                                              FilledButton.icon(
                                                onPressed: () => _showKembalikanDialog(peminjaman),
                                                icon: const Icon(Icons.assignment_return, size: 20),
                                                label: const Text('Kembalikan'),
                                                style: FilledButton.styleFrom(
                                                  foregroundColor: colorScheme.onPrimary,
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                ),
                                              ),
                                            if (peminjaman.sudahDikembalikan)
                                              Row(
                                                children: [
                                                  OutlinedButton.icon(
                                                    onPressed: () => _showTolakDialog(peminjaman),
                                                    icon: const Icon(Icons.cancel, size: 20),
                                                    label: const Text('Tolak'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: colorScheme.error,
                                                      side: BorderSide(color: colorScheme.error),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  FilledButton.icon(
                                                    onPressed: () => _showSetujuDialog(peminjaman),
                                                    icon: const Icon(Icons.check_circle, size: 20),
                                                    label: const Text('Setuju'),
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: colorScheme.tertiary,
                                                      foregroundColor: colorScheme.onTertiary,
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildInfoRow(IconData icon, String text, TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String text, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetujuDialog(Peminjaman peminjaman) async {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final TextEditingController catatanController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: colorScheme.surface,
          title: Text(
            'Setujui Pengembalian',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anda yakin ingin menyetujui pengembalian ${peminjaman.namaBarang}?',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: catatanController,
                  decoration: InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    prefixIcon: const Icon(Icons.note),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.tertiary, width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: TextStyle(color: colorScheme.primary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                _setujuiPengembalian(peminjaman, catatanController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Setuju'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTolakDialog(Peminjaman peminjaman) async {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final TextEditingController alasanController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: colorScheme.surface,
          title: Text(
            'Tolak Pengembalian',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anda yakin ingin menolak pengembalian ${peminjaman.namaBarang}?',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: alasanController,
                  decoration: InputDecoration(
                    labelText: 'Alasan Penolakan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    prefixIcon: const Icon(Icons.report_problem),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.error, width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: TextStyle(color: colorScheme.primary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                _tolakPengembalian(peminjaman, alasanController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setujuiPengembalian(Peminjaman peminjaman, String catatan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = {
        'peminjaman_id': peminjaman.id,
        'status': 'disetujui',
        'catatan': catatan,
      };

      final success = await _service.updateStatusPengembalian(data);
      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengembalian berhasil disetujui'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPeminjamanAktif();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyetujui pengembalian. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _tolakPengembalian(Peminjaman peminjaman, String alasan) async {
    if (alasan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan penolakan harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = {
        'peminjaman_id': peminjaman.id,
        'status': 'ditolak',
        'catatan': alasan,
      };

      final success = await _service.updateStatusPengembalian(data);
      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengembalian berhasil ditolak'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPeminjamanAktif();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menolak pengembalian. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



