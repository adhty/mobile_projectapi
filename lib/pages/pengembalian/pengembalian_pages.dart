import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pengembalian_service.dart';
import '../peminjaman/peminjaman_model.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({super.key});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> with TickerProviderStateMixin {
  final PengembalianService _service = PengembalianService();
  bool _isLoading = true;
  List<Peminjaman> _peminjamanAktif = [];
  List<Peminjaman> _filteredPeminjaman = [];

  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _jumlahKembaliController = TextEditingController();
  final TextEditingController _tanggalPengembalianController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _kondisiBarang = 'baik';
  final List<String> _kondisiOptions = ['baik', 'rusak', 'hilang'];

  // Search and filter variables
  bool _isSearching = false;
  String _selectedFilter = 'Semua';
  String _selectedSort = 'Terbaru';
  final List<String> _filterOptions = ['Semua', 'Belum Dikembalikan', 'Menunggu Persetujuan'];
  final List<String> _sortOptions = ['Terbaru', 'Terlama', 'Nama A-Z', 'Nama Z-A'];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadPeminjamanAktif();
    _tanggalPengembalianController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _catatanController.dispose();
    _jumlahKembaliController.dispose();
    _tanggalPengembalianController.dispose();
    super.dispose();
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
        _filteredPeminjaman = peminjamanAktif;
        _isLoading = false;
      });
      _animationController.forward();
      _applyFiltersAndSort();
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

  void _filterData() {
    setState(() {
      _filteredPeminjaman = _peminjamanAktif.where((peminjaman) {
        final searchTerm = _searchController.text.toLowerCase();
        final namaBarang = peminjaman.namaBarang.toLowerCase();
        final alasanPinjam = peminjaman.alasanPinjam.toLowerCase();

        final matchesSearch = namaBarang.contains(searchTerm) ||
                             alasanPinjam.contains(searchTerm);

        return matchesSearch;
      }).toList();
    });
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    setState(() {
      // Apply filters
      _filteredPeminjaman = _peminjamanAktif.where((peminjaman) {
        final searchTerm = _searchController.text.toLowerCase();
        final namaBarang = peminjaman.namaBarang.toLowerCase();
        final alasanPinjam = peminjaman.alasanPinjam.toLowerCase();

        final matchesSearch = searchTerm.isEmpty ||
                             namaBarang.contains(searchTerm) ||
                             alasanPinjam.contains(searchTerm);

        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'Belum Dikembalikan':
            matchesFilter = !peminjaman.sudahDikembalikan;
            break;
          case 'Menunggu Persetujuan':
            matchesFilter = peminjaman.sudahDikembalikan;
            break;
          default:
            matchesFilter = true;
        }

        return matchesSearch && matchesFilter;
      }).toList();

      // Apply sorting
      switch (_selectedSort) {
        case 'Terlama':
          _filteredPeminjaman.sort((a, b) => a.tglPinjam.compareTo(b.tglPinjam));
          break;
        case 'Nama A-Z':
          _filteredPeminjaman.sort((a, b) => a.namaBarang.compareTo(b.namaBarang));
          break;
        case 'Nama Z-A':
          _filteredPeminjaman.sort((a, b) => b.namaBarang.compareTo(a.namaBarang));
          break;
        default: // Terbaru
          _filteredPeminjaman.sort((a, b) => b.tglPinjam.compareTo(a.tglPinjam));
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterData();
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Filter & Urutkan', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter berdasarkan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _filterOptions.map((filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      Navigator.pop(context);
                      _applyFiltersAndSort();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Urutkan berdasarkan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _sortOptions.map((sort) {
                  return FilterChip(
                    label: Text(sort),
                    selected: _selectedSort == sort,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSort = sort;
                      });
                      Navigator.pop(context);
                      _applyFiltersAndSort();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'Semua';
                  _selectedSort = 'Terbaru';
                });
                Navigator.pop(context);
                _applyFiltersAndSort();
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showStatistics() {
    final totalItems = _peminjamanAktif.length;
    final belumDikembalikan = _peminjamanAktif.where((p) => !p.sudahDikembalikan).length;
    final menungguPersetujuan = _peminjamanAktif.where((p) => p.sudahDikembalikan).length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Statistik Pengembalian', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatCard('Total Peminjaman Aktif', totalItems.toString(), Icons.inventory, Colors.blue),
              const SizedBox(height: 12),
              _buildStatCard('Belum Dikembalikan', belumDikembalikan.toString(), Icons.pending, Colors.orange),
              const SizedBox(height: 12),
              _buildStatCard('Menunggu Persetujuan', menungguPersetujuan.toString(), Icons.hourglass_empty, Colors.green),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
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
      Navigator.of(context).pop(); // Tutup loading dialog

      if (success) {
        setState(() {
          peminjaman.sudahDikembalikan = true;
        });

        // Tampilkan alert sukses yang lebih informatif
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  const Text('Pengembalian Berhasil'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengembalian ${peminjaman.namaBarang} telah berhasil diajukan.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Barang', peminjaman.namaBarang),
                        _buildDetailRow('Jumlah Dikembalikan', jumlahKembali.toString()),
                        _buildDetailRow('Tanggal Pengembalian', _tanggalPengembalianController.text),
                        _buildDetailRow('Kondisi Barang', _kondisiBarang),
                        if (_catatanController.text.isNotEmpty)
                          _buildDetailRow('Catatan', _catatanController.text),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status pengembalian Anda saat ini "Menunggu Persetujuan". Admin akan memverifikasi pengembalian Anda.',
                    style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadPeminjamanAktif(); // Refresh data
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengajukan pengembalian barang. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Tutup loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method untuk menampilkan detail dalam alert
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari barang atau alasan...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('Pengembalian Barang'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filter & Urutkan',
            ),
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: _showStatistics,
              tooltip: 'Statistik',
            ),
          ],
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Tutup Pencarian' : 'Cari',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Summary Cards
                  if (_peminjamanAktif.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Aktif',
                              _peminjamanAktif.length.toString(),
                              Icons.inventory,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Belum Kembali',
                              _peminjamanAktif.where((p) => !p.sudahDikembalikan).length.toString(),
                              Icons.pending,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Menunggu',
                              _peminjamanAktif.where((p) => p.sudahDikembalikan).length.toString(),
                              Icons.hourglass_empty,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Content
                  Expanded(
                    child: _filteredPeminjaman.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                     size: 64,
                                     color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Tidak ada hasil pencarian'
                                      : 'Tidak ada peminjaman aktif',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Coba kata kunci lain',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: RefreshIndicator(
                              color: Colors.blue.shade700,
                              onRefresh: _loadPeminjamanAktif,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredPeminjaman.length,
                                itemBuilder: (context, index) {
                                  final peminjaman = _filteredPeminjaman[index];
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
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        // Tampilkan alert sukses
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  const Text('Pengembalian Disetujui'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengembalian ${peminjaman.namaBarang} telah berhasil disetujui.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Barang', peminjaman.namaBarang),
                        _buildDetailRow('Status', 'Disetujui'),
                        if (catatan.isNotEmpty)
                          _buildDetailRow('Catatan', catatan),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Barang telah berhasil dikembalikan dan transaksi telah selesai.',
                    style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadPeminjamanAktif(); // Refresh data
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
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
        // Tampilkan alert penolakan
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  const Text('Pengembalian Ditolak'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengembalian ${peminjaman.namaBarang} telah ditolak.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.error.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Barang', peminjaman.namaBarang),
                        _buildDetailRow('Status', 'Ditolak'),
                        _buildDetailRow('Alasan Penolakan', alasan),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Peminjam perlu mengajukan pengembalian ulang dengan informasi yang benar.',
                    style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadPeminjamanAktif(); // Refresh data
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
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


