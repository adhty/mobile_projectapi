import 'package:flutter/material.dart';
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
  final TextEditingController _tanggalPinjamController = TextEditingController();
  final TextEditingController _tanggalKembaliController = TextEditingController();

  final PeminjamanService _service = PeminjamanService();
  final BarangService _barangService = BarangService();
  
  List<Barang> _barangList = [];
  Barang? _selectedBarang;
  bool _isLoading = true;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data barang: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final data = {
        'user_id': 2,
        'barang_id': _selectedBarang!.id,
        'alasan_pinjam': _alasanPinjamController.text,
        'jumlah': int.parse(_jumlahController.text),
        'tanggal_pinjam': dateFormatter.format(DateTime.parse(_tanggalPinjamController.text)),
        'tanggal_kembali': dateFormatter.format(DateTime.parse(_tanggalKembaliController.text)),
        'status': 'pending',
      };

      print(data);

      final success = await _service.pinjamBarang(data);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mengajukan peminjaman')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal meminjam barang')),
        );
      }
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
      appBar: AppBar(title: const Text('Form Peminjaman')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<Barang>(
                      value: _selectedBarang,
                      decoration: const InputDecoration(labelText: 'Pilih Barang'),
                      items: _barangList.map((barang) {
                        return DropdownMenuItem<Barang>(
                          value: barang,
                          child: Text('${barang.nama} (Stok: ${barang.jumlahBarang})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBarang = value;
                        });
                      },
                      validator: (value) => value == null ? 'Silahkan pilih barang' : null,
                    ),
                    TextFormField(
                      controller: _alasanPinjamController,
                      decoration: const InputDecoration(labelText: 'Alasan Peminjaman'),
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Alasan peminjaman harus diisi' : null,
                    ),
                    TextFormField(
                      controller: _jumlahController,
                      decoration: const InputDecoration(labelText: 'Jumlah'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Jumlah harus diisi';
                        }
                        final jumlah = int.tryParse(value);
                        if (jumlah == null || jumlah <= 0) {
                          return 'Jumlah harus berupa angka positif';
                        }
                        if (_selectedBarang != null && jumlah > _selectedBarang!.jumlahBarang) {
                          return 'Jumlah melebihi stok yang tersedia';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _tanggalPinjamController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Pinjam',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _tanggalPinjamController),
                      validator: (value) =>
                          value!.isEmpty ? 'Tanggal Pinjam harus diisi' : null,
                    ),
                    TextFormField(
                      controller: _tanggalKembaliController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Kembali',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _tanggalKembaliController),
                      validator: (value) =>
                          value!.isEmpty ? 'Tanggal Kembali harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Pinjam Barang'),
                    ),
                  ],
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