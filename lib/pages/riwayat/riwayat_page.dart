import 'package:flutter/material.dart';
import '../peminjaman/peminjaman_model.dart';
import '../peminjaman/peminjaman_service.dart';
import '../pengembalian/pengembalian_model.dart';
import '../pengembalian/pengembalian_service.dart';
import 'package:intl/intl.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PeminjamanService _peminjamanService = PeminjamanService();
  final PengembalianService _pengembalianService = PengembalianService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingPeminjaman = true;
  bool _isLoadingPengembalian = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  String _selectedSort = 'Terbaru';

  List<Peminjaman> _riwayatPeminjaman = [];
  List<Pengembalian> _riwayatPengembalian = [];
  List<Peminjaman> _filteredPeminjaman = [];
  List<Pengembalian> _filteredPengembalian = [];

  final List<String> _filterOptions = ['Semua', 'Disetujui', 'Ditolak', 'Menunggu', 'Dikembalikan'];
  final List<String> _sortOptions = ['Terbaru', 'Terlama', 'A-Z', 'Z-A'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_searchQuery.isNotEmpty) {
        setState(() {}); // Update UI untuk menampilkan jumlah hasil yang benar
      }
    });
    _loadRiwayatPeminjaman();
    _loadRiwayatPengembalian();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRiwayatPeminjaman() async {
    setState(() {
      _isLoadingPeminjaman = true;
    });

    try {
      final riwayat = await _peminjamanService.fetchRiwayatPeminjaman();

      // Update nama barang untuk setiap peminjaman
      await _pengembalianService.updateBarangNames(riwayat);

      setState(() {
        _riwayatPeminjaman = riwayat;
        _filteredPeminjaman = riwayat;
        _isLoadingPeminjaman = false;
      });
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _isLoadingPeminjaman = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat peminjaman: $e')),
        );
      }
    }
  }

  Future<void> _loadRiwayatPengembalian() async {
    setState(() {
      _isLoadingPengembalian = true;
    });

    try {
      final riwayat = await _pengembalianService.fetchRiwayatPengembalian();

      // Update nama barang untuk setiap pengembalian
      await _pengembalianService.updatePengembalianBarangNames(riwayat);

      setState(() {
        _riwayatPengembalian = riwayat;
        _filteredPengembalian = riwayat;
        _isLoadingPengembalian = false;
      });
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _isLoadingPengembalian = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat pengembalian: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadRiwayatPeminjaman(),
      _loadRiwayatPengembalian(),
    ]);
  }

  void _filterData(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    // Filter berdasarkan search query
    List<Peminjaman> filteredPeminjaman = _riwayatPeminjaman;
    List<Pengembalian> filteredPengembalian = _riwayatPengembalian;

    if (_searchQuery.isNotEmpty) {
      filteredPeminjaman = _riwayatPeminjaman.where((peminjaman) {
        return peminjaman.namaBarang.toLowerCase().contains(_searchQuery) ||
               peminjaman.alasanPinjam.toLowerCase().contains(_searchQuery) ||
               peminjaman.status.toLowerCase().contains(_searchQuery) ||
               peminjaman.tglPinjam.toLowerCase().contains(_searchQuery);
      }).toList();

      filteredPengembalian = _riwayatPengembalian.where((pengembalian) {
        return pengembalian.namaBarang.toLowerCase().contains(_searchQuery) ||
               pengembalian.kondisi.toLowerCase().contains(_searchQuery) ||
               pengembalian.status.toLowerCase().contains(_searchQuery) ||
               pengembalian.tanggalKembali.toLowerCase().contains(_searchQuery) ||
               pengembalian.catatan.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filter berdasarkan status
    if (_selectedFilter != 'Semua') {
      filteredPeminjaman = filteredPeminjaman.where((peminjaman) {
        return peminjaman.status.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();

      filteredPengembalian = filteredPengembalian.where((pengembalian) {
        return pengembalian.status.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }

    // Sorting
    switch (_selectedSort) {
      case 'Terbaru':
        filteredPeminjaman.sort((a, b) => b.tglPinjam.compareTo(a.tglPinjam));
        filteredPengembalian.sort((a, b) => b.tanggalKembali.compareTo(a.tanggalKembali));
        break;
      case 'Terlama':
        filteredPeminjaman.sort((a, b) => a.tglPinjam.compareTo(b.tglPinjam));
        filteredPengembalian.sort((a, b) => a.tanggalKembali.compareTo(b.tanggalKembali));
        break;
      case 'A-Z':
        filteredPeminjaman.sort((a, b) => a.namaBarang.compareTo(b.namaBarang));
        filteredPengembalian.sort((a, b) => a.namaBarang.compareTo(b.namaBarang));
        break;
      case 'Z-A':
        filteredPeminjaman.sort((a, b) => b.namaBarang.compareTo(a.namaBarang));
        filteredPengembalian.sort((a, b) => b.namaBarang.compareTo(a.namaBarang));
        break;
    }

    _filteredPeminjaman = filteredPeminjaman;
    _filteredPengembalian = filteredPengembalian;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterData('');
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter & Urutkan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter berdasarkan status:', style: TextStyle(fontWeight: FontWeight.bold)),
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
    // Hitung statistik peminjaman
    final totalPeminjaman = _riwayatPeminjaman.length;
    final disetujui = _riwayatPeminjaman.where((p) => p.status.toLowerCase() == 'disetujui').length;
    final ditolak = _riwayatPeminjaman.where((p) => p.status.toLowerCase() == 'ditolak').length;
    final menunggu = _riwayatPeminjaman.where((p) => p.status.toLowerCase() == 'menunggu').length;
    final dikembalikan = _riwayatPeminjaman.where((p) => p.status.toLowerCase() == 'dikembalikan').length;

    // Hitung statistik pengembalian
    final totalPengembalian = _riwayatPengembalian.length;
    final kondisiBaik = _riwayatPengembalian.where((p) => p.kondisi.toLowerCase() == 'baik').length;
    final kondisiRusak = _riwayatPengembalian.where((p) => p.kondisi.toLowerCase() == 'rusak').length;
    final kondisiHilang = _riwayatPengembalian.where((p) => p.kondisi.toLowerCase() == 'hilang').length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Statistik Riwayat'),
            ],
          ),
          content: SingleChildScrollView/*  */(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard(
                  'Peminjaman',
                  Icons.arrow_circle_down,
                  Colors.blue,
                  [
                    _buildStatItem('Total', totalPeminjaman, Colors.blue),
                    _buildStatItem('Disetujui', disetujui, Colors.green),
                    _buildStatItem('Ditolak', ditolak, Colors.red),
                    _buildStatItem('Menunggu', menunggu, Colors.orange),
                    _buildStatItem('Dikembalikan', dikembalikan, Colors.purple),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Pengembalian',
                  Icons.arrow_circle_up,
                  Colors.green,
                  [
                    _buildStatItem('Total', totalPengembalian, Colors.green),
                    _buildStatItem('Kondisi Baik', kondisiBaik, Colors.green),
                    _buildStatItem('Kondisi Rusak', kondisiRusak, Colors.orange),
                    _buildStatItem('Hilang', kondisiHilang, Colors.red),
                  ],
                ),
              ],
            ),
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

  Widget _buildStatCard(String title, IconData icon, Color color, List<Widget> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPeminjamanDetail(Peminjaman peminjaman) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getStatusColor(peminjaman.status),
                radius: 16,
                child: Icon(
                  _getStatusIcon(peminjaman.status),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  peminjaman.namaBarang,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Jumlah', '${peminjaman.jumlah} unit'),
              _buildDetailRow('Tanggal Pinjam', peminjaman.tglPinjam),
              if (peminjaman.tglKembali != null)
                _buildDetailRow('Tanggal Kembali', peminjaman.tglKembali!),
              _buildDetailRow('Alasan', peminjaman.alasanPinjam),
              _buildDetailRow('Status', _getStatusText(peminjaman.status)),
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

  void _showPengembalianDetail(Pengembalian pengembalian) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getKondisiColor(pengembalian.kondisi),
                radius: 16,
                child: Icon(
                  _getKondisiIcon(pengembalian.kondisi),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pengembalian.namaBarang,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Jumlah', '${pengembalian.jumlah} unit'),
              _buildDetailRow('Tanggal Kembali', pengembalian.tanggalKembali),
              _buildDetailRow('Kondisi', pengembalian.kondisi.toUpperCase()),
              _buildDetailRow('Status', _getStatusText(pengembalian.status)),
              if (pengembalian.catatan.isNotEmpty)
                _buildDetailRow('Catatan', pengembalian.catatan),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showQuickActions,
      backgroundColor: Colors.blue.shade700,
      icon: const Icon(Icons.more_horiz, color: Colors.white),
      label: const Text(
        'Aksi',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aksi Cepat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.refresh,
                    label: 'Refresh',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _refreshData();
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.filter_list,
                    label: 'Filter',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.analytics,
                    label: 'Statistik',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _showStatistics();
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.share,
                    label: 'Bagikan',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _shareData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _shareData() {
    final currentTab = _tabController.index;
    final data = currentTab == 0 ? _filteredPeminjaman : _filteredPengembalian;
    final type = currentTab == 0 ? 'Peminjaman' : 'Pengembalian';

    String shareText = 'Riwayat $type\n\n';

    if (currentTab == 0) {
      for (var item in _filteredPeminjaman) {
        shareText += '• ${item.namaBarang}\n';
        shareText += '  Jumlah: ${item.jumlah}\n';
        shareText += '  Status: ${item.status}\n';
        shareText += '  Tanggal: ${item.tglPinjam}\n\n';
      }
    } else {
      for (var item in _filteredPengembalian) {
        shareText += '• ${item.namaBarang}\n';
        shareText += '  Jumlah: ${item.jumlah}\n';
        shareText += '  Kondisi: ${item.kondisi}\n';
        shareText += '  Tanggal: ${item.tanggalKembali}\n\n';
      }
    }

    shareText += 'Total: ${data.length} item';

    // Untuk implementasi sharing yang sesungguhnya, Anda bisa menggunakan package share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data siap dibagikan: ${data.length} item'),
        action: SnackBarAction(
          label: 'Salin',
          onPressed: () {
            // Implementasi copy to clipboard
          },
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) {
      return Text(text);
    }

    final startIndex = lowerText.indexOf(lowerQuery);
    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          if (startIndex > 0)
            TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
              backgroundColor: Colors.yellow.shade300,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (endIndex < text.length)
            TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari riwayat...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _filterData,
              )
            : const Text('Riwayat Aktivitas'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Peminjaman'),
            Tab(text: 'Pengembalian'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search results info
          if (_searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Text(
                'Hasil pencarian "$_searchQuery": ${_tabController.index == 0 ? _filteredPeminjaman.length : _filteredPengembalian.length} item',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
            ),

          // Tab content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Peminjaman
                  _isLoadingPeminjaman
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPeminjamanList(),

                  // Tab Pengembalian
                  _isLoadingPengembalian
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPengembalianList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeminjamanList() {
    if (_filteredPeminjaman.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada riwayat peminjaman'
                  : 'Tidak ada hasil pencarian',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredPeminjaman.length,
      itemBuilder: (context, index) {
        final peminjaman = _filteredPeminjaman[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 4,
            shadowColor: Colors.blue.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showPeminjamanDetail(peminjaman),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      _getStatusColor(peminjaman.status).withOpacity(0.05),
                    ],
                  ),
                ),
                child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(peminjaman.status),
              child: Icon(
                _getStatusIcon(peminjaman.status),
                color: Colors.white,
              ),
            ),
            title: _searchQuery.isNotEmpty
                ? _buildHighlightedText(peminjaman.namaBarang, _searchQuery)
                : Text(
                    peminjaman.namaBarang,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Jumlah: ${peminjaman.jumlah}'),
                Text('Tanggal Pinjam: ${peminjaman.tglPinjam}'),
                if (peminjaman.tglKembali != null)
                  Text('Tanggal Kembali: ${peminjaman.tglKembali}'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(peminjaman.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(peminjaman.status),
                    style: TextStyle(
                      color: _getStatusColor(peminjaman.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPengembalianList() {
    if (_filteredPengembalian.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_return, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada riwayat pengembalian'
                  : 'Tidak ada hasil pencarian',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredPengembalian.length,
      itemBuilder: (context, index) {
        final pengembalian = _filteredPengembalian[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 4,
            shadowColor: Colors.green.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showPengembalianDetail(pengembalian),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      _getKondisiColor(pengembalian.kondisi).withOpacity(0.05),
                    ],
                  ),
                ),
                child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getKondisiColor(pengembalian.kondisi),
              child: Icon(
                _getKondisiIcon(pengembalian.kondisi),
                color: Colors.white,
              ),
            ),
            title: _searchQuery.isNotEmpty
                ? _buildHighlightedText(pengembalian.namaBarang, _searchQuery)
                : Text(
                    pengembalian.namaBarang,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Jumlah: ${pengembalian.jumlah}'),
                Text('Tanggal Kembali: ${pengembalian.tanggalKembali}'),
                if (pengembalian.catatan.isNotEmpty)
                  Text('Catatan: ${pengembalian.catatan}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getKondisiColor(pengembalian.kondisi).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Kondisi: ${pengembalian.kondisi[0].toUpperCase()}${pengembalian.kondisi.substring(1)}',
                        style: TextStyle(
                          color: _getKondisiColor(pengembalian.kondisi),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(pengembalian.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(pengembalian.status),
                        style: TextStyle(
                          color: _getStatusColor(pengembalian.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'menunggu':
        return Colors.orange;
      case 'dikembalikan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      case 'menunggu':
        return Icons.hourglass_empty;
      case 'dikembalikan':
        return Icons.assignment_return;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'menunggu':
        return 'Menunggu';
      case 'dikembalikan':
        return 'Dikembalikan';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _getKondisiColor(String kondisi) {
    switch (kondisi.toLowerCase()) {
      case 'baik':
        return Colors.green;
      case 'rusak':
        return Colors.orange;
      case 'hilang':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getKondisiIcon(String kondisi) {
    switch (kondisi.toLowerCase()) {
      case 'baik':
        return Icons.thumb_up;
      case 'rusak':
        return Icons.build;
      case 'hilang':
        return Icons.help_outline;
      default:
        return Icons.help;
    }
  }
}

