import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../peminjaman/peminjaman_model.dart';
import 'pengembalian_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({super.key});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tanggalKembaliController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  
  final PengembalianService _service = PengembalianService();
  
  List<Peminjaman> _peminjamanList = [];
  Peminjaman? _selectedPeminjaman;
  String? _selectedKondisi;
  bool _isLoading = true;
  String _errorMessage = '';
  
  final List<String> _kondisiOptions = ['Baik', 'Rusak Ringan', 'Rusak Berat'];

  @override
  void initState() {
    super.initState();
    _loadPeminjamanAktif();
    // Set tanggal kembali default ke hari ini
    _tanggalKembaliController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _loadPeminjamanAktif() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get user ID from SharedPreferences or use a default value
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1; // Default to 1 if not found
      
      print('Fetching active peminjaman for user ID: $userId');
      final peminjaman = await _service.fetchPeminjamanAktif(userId);
      
      setState(() {
        _peminjamanList = peminjaman;
        _isLoading = false;
      });
      
      print('Loaded ${peminjaman.length} active peminjaman');
    } catch (e) {
      print('Error loading peminjaman: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final data = {
          'peminjaman_id': _selectedPeminjaman!.id,
          'tanggal_kembali': _tanggalKembaliController.text,
          'kondisi': _selectedKondisi,
          'catatan': _catatanController.text,
          'status': 'pending', // Status awal pending, menunggu persetujuan admin
        };

        final success = await _service.kembalikanBarang(data);
        
        setState(() {
          _isLoading = false;
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil mengajukan pengembalian')),
          );
          _resetForm();
          // Reload data setelah submit
          _loadPeminjamanAktif();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengembalikan barang')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedPeminjaman = null;
      _selectedKondisi = null;
      _tanggalKembaliController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _catatanController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Pengembalian')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPeminjamanAktif,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _peminjamanList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Tidak ada peminjaman aktif'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPeminjamanAktif,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            DropdownButtonFormField<Peminjaman>(
                              value: _selectedPeminjaman,
                              decoration: const InputDecoration(labelText: 'Pilih Peminjaman'),
                              items: _peminjamanList.map((peminjaman) {
                                return DropdownMenuItem<Peminjaman>(
                                  value: peminjaman,
                                  child: Text('${peminjaman.namaBarang ?? "Barang"} (${peminjaman.jumlah ?? 0} unit)'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPeminjaman = value;
                                });
                              },
                              validator: (value) => value == null ? 'Silahkan pilih peminjaman' : null,
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
                            DropdownButtonFormField<String>(
                              value: _selectedKondisi,
                              decoration: const InputDecoration(labelText: 'Kondisi Barang'),
                              items: _kondisiOptions.map((kondisi) {
                                return DropdownMenuItem<String>(
                                  value: kondisi,
                                  child: Text(kondisi),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedKondisi = value;
                                });
                              },
                              validator: (value) => value == null ? 'Silahkan pilih kondisi barang' : null,
                            ),
                            TextFormField(
                              controller: _catatanController,
                              decoration: const InputDecoration(labelText: 'Catatan'),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _submit,
                              child: const Text('Kembalikan Barang'),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  @override
  void dispose() {
    _tanggalKembaliController.dispose();
    _catatanController.dispose();
    super.dispose();
  }
}

