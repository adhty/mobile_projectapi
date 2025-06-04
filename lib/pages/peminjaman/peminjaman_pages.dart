import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'peminjaman_service.dart';
import '../barang/barang_model.dart';
import '../barang/barang_service.dart';
import 'package:intl/intl.dart';

class PeminjamanPage extends StatefulWidget {
  const PeminjamanPage({super.key});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _alasanPinjamController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _tanggalPinjamController =
      TextEditingController();
  final TextEditingController _tanggalKembaliController =
      TextEditingController();

  final PeminjamanService _service = PeminjamanService();
  final BarangService _barangService = BarangService();

  List<Barang> _barangList = [];
  Barang? _selectedBarang;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  Future<void> _loadBarang() async {
    try {
      final barang = await _barangService.fetchBarang();
      setState(() {
        _barangList = barang;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data barang: $e')));
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final dateFormatter = DateFormat('yyyy-MM-dd');

      final data = {
        'barang_id': _selectedBarang!.id,
        'alasan_pinjam': _alasanPinjamController.text,
        'jumlah': int.parse(_jumlahController.text),
        'status': 'menunggu',
        'tanggal_pinjam': dateFormatter.format(
          DateTime.parse(_tanggalPinjamController.text),
        ),
        'tanggal_kembali': dateFormatter.format(
          DateTime.parse(_tanggalKembaliController.text),
        ),
      };

      final success = await _service.pinjamBarang(data);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(success ? 'Sukses' : 'Gagal'),
              content: Text(
                success
                    ? 'Berhasil mengajukan peminjaman.'
                    : 'Gagal meminjam barang. Silakan coba lagi.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
                    if (success) _resetForm(); // Reset hanya jika sukses
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _selectedBarang = null;
      _alasanPinjamController.clear();
      _jumlahController.clear();
      _tanggalPinjamController.clear();
      _tanggalKembaliController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Peminjaman'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade50, Colors.white],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.blue.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            const Text(
                              'Formulir Peminjaman Barang',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<Barang>(
                              value: _selectedBarang,
                              decoration: InputDecoration(
                                labelText: 'Pilih Barang',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                prefixIcon: const Icon(Icons.inventory),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              items:
                                  _barangList.map((barang) {
                                    return DropdownMenuItem<Barang>(
                                      value: barang,
                                      child: Text(
                                        '${barang.nama} (Stok: ${barang.jumlahBarang})',
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBarang = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Silahkan pilih barang'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _alasanPinjamController,
                              decoration: InputDecoration(
                                labelText: 'Alasan Peminjaman',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              maxLines: 3,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Alasan peminjaman harus diisi'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _jumlahController,
                              decoration: InputDecoration(
                                labelText: 'Jumlah',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                prefixIcon: const Icon(Icons.numbers),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Jumlah harus diisi';
                                }
                                final jumlah = int.tryParse(value);
                                if (jumlah == null || jumlah <= 0) {
                                  return 'Jumlah harus berupa angka positif';
                                }
                                if (_selectedBarang != null &&
                                    jumlah > _selectedBarang!.jumlahBarang) {
                                  return 'Jumlah melebihi stok yang tersedia';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _tanggalPinjamController,
                              decoration: InputDecoration(
                                labelText: 'Tanggal Pinjam',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              readOnly: true,
                              onTap:
                                  () => _selectDate(
                                    context,
                                    _tanggalPinjamController,
                                  ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Tanggal Pinjam harus diisi'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _tanggalKembaliController,
                              decoration: InputDecoration(
                                labelText: 'Tanggal Kembali',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                prefixIcon: const Icon(Icons.event),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              readOnly: true,
                              onTap:
                                  () => _selectDate(
                                    context,
                                    _tanggalKembaliController,
                                  ),
                              validator: (value) {
                                if (value!.isEmpty)
                                  return 'Tanggal Kembali harus diisi';
                                if (_tanggalPinjamController.text.isEmpty)
                                  return 'Isi tanggal pinjam dulu';
                                final pinjamDate = DateTime.parse(
                                  _tanggalPinjamController.text,
                                );
                                final kembaliDate = DateTime.parse(value);
                                if (kembaliDate.isBefore(pinjamDate)) {
                                  return 'Tanggal kembali harus setelah tanggal pinjam';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _submit,
                                icon:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.send),
                                label: Text(
                                  _isSubmitting
                                      ? 'Mengirim...'
                                      : 'AJUKAN PEMINJAMAN',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 3,
                                  shadowColor: Colors.blueAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _resetForm,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset Form'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _alasanPinjamController.dispose();
    _jumlahController.dispose();
    _tanggalPinjamController.dispose();
    _tanggalKembaliController.dispose();
    super.dispose();
  }
}
