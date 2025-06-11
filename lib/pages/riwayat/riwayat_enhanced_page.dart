import 'package:flutter/material.dart';
import '../peminjaman/peminjaman_model.dart';
import '../peminjaman/peminjaman_service.dart';
import '../pengembalian/pengembalian_model.dart';
import '../pengembalian/pengembalian_service.dart';
import 'package:intl/intl.dart';

// Combined history item for unified display
class HistoryItem {
  final String id;
  final String type; // 'peminjaman' or 'pengembalian'
  final String namaBarang;
  final String tanggal;
  final String status;
  final int jumlah;
  final String? alasan;
  final String? kondisi;
  final String? catatan;
  final dynamic originalData;

  HistoryItem({
    required this.id,
    required this.type,
    required this.namaBarang,
    required this.tanggal,
    required this.status,
    required this.jumlah,
    this.alasan,
    this.kondisi,
    this.catatan,
    this.originalData,
  });

  factory HistoryItem.fromPeminjaman(Peminjaman peminjaman) {
    return HistoryItem(
      id: peminjaman.id.toString(),
      type: 'peminjaman',
      namaBarang: peminjaman.namaBarang,
      tanggal: peminjaman.tglPinjam,
      status: peminjaman.status,
      jumlah: peminjaman.jumlah,
      alasan: peminjaman.alasanPinjam,
      originalData: peminjaman,
    );
  }

  factory HistoryItem.fromPengembalian(Pengembalian pengembalian) {
    return HistoryItem(
      id: pengembalian.id.toString(),
      type: 'pengembalian',
      namaBarang: pengembalian.namaBarang,
      tanggal: pengembalian.tanggalKembali,
      status: pengembalian.status,
      jumlah: pengembalian.jumlah,
      kondisi: pengembalian.kondisi,
      catatan: pengembalian.catatan,
      originalData: pengembalian,
    );
  }
}

class RiwayatEnhancedPage extends StatefulWidget {
  const RiwayatEnhancedPage({super.key});

  @override
  State<RiwayatEnhancedPage> createState() => _RiwayatEnhancedPageState();
}

class _RiwayatEnhancedPageState extends State<RiwayatEnhancedPage> with TickerProviderStateMixin {
  final PeminjamanService _peminjamanService = PeminjamanService();
  final PengembalianService _pengembalianService = PengembalianService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedFilter = 'Semua';
  String _selectedSort = 'Terbaru';
  String _selectedType = 'Semua';

  List<HistoryItem> _allHistory = [];
  List<HistoryItem> _filteredHistory = [];

  final List<String> _filterOptions = ['Semua', 'Disetujui', 'Ditolak', 'Menunggu'];
  final List<String> _sortOptions = ['Terbaru', 'Terlama', 'Nama A-Z', 'Nama Z-A'];
  final List<String> _typeOptions = ['Semua', 'Peminjaman', 'Pengembalian'];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAllHistory();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load both peminjaman and pengembalian data
      final peminjamanFuture = _peminjamanService.fetchRiwayatPeminjaman();
      final pengembalianFuture = _pengembalianService.fetchRiwayatPengembalian();

      final results = await Future.wait([peminjamanFuture, pengembalianFuture]);
      final riwayatPeminjaman = results[0] as List<Peminjaman>;
      final riwayatPengembalian = results[1] as List<Pengembalian>;

      // Update nama barang
      await _pengembalianService.updateBarangNames(riwayatPeminjaman);
      await _pengembalianService.updatePengembalianBarangNames(riwayatPengembalian);

      // Convert to unified history items
      final List<HistoryItem> allHistory = [];
      
      for (final peminjaman in riwayatPeminjaman) {
        allHistory.add(HistoryItem.fromPeminjaman(peminjaman));
      }
      
      for (final pengembalian in riwayatPengembalian) {
        allHistory.add(HistoryItem.fromPengembalian(pengembalian));
      }

      setState(() {
        _allHistory = allHistory;
        _filteredHistory = allHistory;
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
          SnackBar(content: Text('Gagal memuat riwayat: $e')),
        );
      }
    }
  }

  void _filterData() {
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredHistory = _allHistory.where((item) {
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
            item.namaBarang.toLowerCase().contains(searchTerm) ||
            item.status.toLowerCase().contains(searchTerm) ||
            (item.alasan?.toLowerCase().contains(searchTerm) ?? false) ||
            (item.kondisi?.toLowerCase().contains(searchTerm) ?? false) ||
            (item.catatan?.toLowerCase().contains(searchTerm) ?? false);

        final matchesFilter = _selectedFilter == 'Semua' ||
            item.status.toLowerCase() == _selectedFilter.toLowerCase();

        final matchesType = _selectedType == 'Semua' ||
            item.type.toLowerCase() == _selectedType.toLowerCase();

        return matchesSearch && matchesFilter && matchesType;
      }).toList();

      // Apply sorting
      switch (_selectedSort) {
        case 'Terlama':
          _filteredHistory.sort((a, b) => a.tanggal.compareTo(b.tanggal));
          break;
        case 'Nama A-Z':
          _filteredHistory.sort((a, b) => a.namaBarang.compareTo(b.namaBarang));
          break;
        case 'Nama Z-A':
          _filteredHistory.sort((a, b) => b.namaBarang.compareTo(a.namaBarang));
          break;
        default: // Terbaru
          _filteredHistory.sort((a, b) => b.tanggal.compareTo(a.tanggal));
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'menunggu':
        return Colors.orange;
      case 'selesai':
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
      case 'selesai':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  IconData _getTypeIcon(String type) {
    return type == 'peminjaman' ? Icons.arrow_circle_down : Icons.arrow_circle_up;
  }

  Color _getTypeColor(String type) {
    return type == 'peminjaman' ? Colors.blue : Colors.green;
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
              const Text('Tipe:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _typeOptions.map((type) {
                  return FilterChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                      Navigator.pop(context);
                      _applyFiltersAndSort();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text('Urutkan:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  _selectedType = 'Semua';
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
    final totalPeminjaman = _allHistory.where((h) => h.type == 'peminjaman').length;
    final totalPengembalian = _allHistory.where((h) => h.type == 'pengembalian').length;
    final disetujui = _allHistory.where((h) => h.status.toLowerCase() == 'disetujui').length;
    final ditolak = _allHistory.where((h) => h.status.toLowerCase() == 'ditolak').length;
    final menunggu = _allHistory.where((h) => h.status.toLowerCase() == 'menunggu').length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Statistik Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatCard('Total Peminjaman', totalPeminjaman.toString(), Icons.arrow_circle_down, Colors.blue),
              const SizedBox(height: 12),
              _buildStatCard('Total Pengembalian', totalPengembalian.toString(), Icons.arrow_circle_up, Colors.green),
              const SizedBox(height: 12),
              _buildStatCard('Disetujui', disetujui.toString(), Icons.check_circle, Colors.green),
              const SizedBox(height: 12),
              _buildStatCard('Ditolak', ditolak.toString(), Icons.cancel, Colors.red),
              const SizedBox(height: 12),
              _buildStatCard('Menunggu', menunggu.toString(), Icons.hourglass_empty, Colors.orange),
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
              )
            : const Text('Riwayat Lengkap'),
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
                  if (_allHistory.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total',
                              _allHistory.length.toString(),
                              Icons.history,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Peminjaman',
                              _allHistory.where((h) => h.type == 'peminjaman').length.toString(),
                              Icons.arrow_circle_down,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Pengembalian',
                              _allHistory.where((h) => h.type == 'pengembalian').length.toString(),
                              Icons.arrow_circle_up,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Content
                  Expanded(
                    child: _filteredHistory.isEmpty
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
                                      : 'Tidak ada riwayat',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Coba kata kunci lain',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              onRefresh: _loadAllHistory,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredHistory.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredHistory[index];
                                  return _buildHistoryCard(item);
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

  Widget _buildHistoryCard(HistoryItem item) {
    final typeColor = _getTypeColor(item.type);
    final statusColor = _getStatusColor(item.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showHistoryDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getTypeIcon(item.type), size: 16, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          item.type == 'peminjaman' ? 'Pinjam' : 'Kembali',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(item.status), size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.namaBarang,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${item.jumlah} unit',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(item.tanggal)),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (item.alasan != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.alasan!,
                        style: TextStyle(color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (item.kondisi != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Kondisi: ${item.kondisi!.toUpperCase()}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDetail(HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getTypeColor(item.type),
                radius: 16,
                child: Icon(
                  _getTypeIcon(item.type),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.namaBarang,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tipe', item.type == 'peminjaman' ? 'Peminjaman' : 'Pengembalian'),
              _buildDetailRow('Jumlah', '${item.jumlah} unit'),
              _buildDetailRow('Tanggal', DateFormat('dd MMMM yyyy').format(DateTime.parse(item.tanggal))),
              _buildDetailRow('Status', item.status.toUpperCase()),
              if (item.alasan != null)
                _buildDetailRow('Alasan', item.alasan!),
              if (item.kondisi != null)
                _buildDetailRow('Kondisi', item.kondisi!.toUpperCase()),
              if (item.catatan != null && item.catatan!.isNotEmpty)
                _buildDetailRow('Catatan', item.catatan!),
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
            width: 80,
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
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
