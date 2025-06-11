import 'package:flutter/material.dart';
import 'barang_model.dart';
import 'barang_service.dart';
import 'barang_detail_page.dart';

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> with TickerProviderStateMixin {
  final BarangService _barangService = BarangService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  List<Barang> _allBarang = [];
  List<Barang> _filteredBarang = [];

  // Filter and sort options
  String _selectedFilter = 'Semua';
  String _selectedSort = 'Nama A-Z';
  String _selectedView = 'Grid';

  final List<String> _filterOptions = ['Semua', 'Tersedia', 'Stok Rendah', 'Habis'];
  final List<String> _sortOptions = ['Nama A-Z', 'Nama Z-A', 'Stok Tertinggi', 'Stok Terendah'];
  final List<String> _viewOptions = ['Grid', 'List'];

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
    _loadBarang();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBarang() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final barangList = await _barangService.fetchBarang();
      setState(() {
        _allBarang = barangList;
        _filteredBarang = barangList;
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
          SnackBar(content: Text('Gagal memuat data barang: $e')),
        );
      }
    }
  }

  void _filterData() {
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredBarang = _allBarang.where((barang) {
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
            barang.nama.toLowerCase().contains(searchTerm);

        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'Tersedia':
            matchesFilter = barang.jumlahBarang > 0;
            break;
          case 'Stok Rendah':
            matchesFilter = barang.jumlahBarang > 0 && barang.jumlahBarang <= 5;
            break;
          case 'Habis':
            matchesFilter = barang.jumlahBarang == 0;
            break;
          default:
            matchesFilter = true;
        }

        return matchesSearch && matchesFilter;
      }).toList();

      // Apply sorting
      switch (_selectedSort) {
        case 'Nama Z-A':
          _filteredBarang.sort((a, b) => b.nama.compareTo(a.nama));
          break;
        case 'Stok Tertinggi':
          _filteredBarang.sort((a, b) => b.jumlahBarang.compareTo(a.jumlahBarang));
          break;
        case 'Stok Terendah':
          _filteredBarang.sort((a, b) => a.jumlahBarang.compareTo(b.jumlahBarang));
          break;
        default: // Nama A-Z
          _filteredBarang.sort((a, b) => a.nama.compareTo(b.nama));
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
              const Text('Filter berdasarkan stok:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 16),
              const Text('Tampilan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _viewOptions.map((view) {
                  return FilterChip(
                    label: Text(view),
                    selected: _selectedView == view,
                    onSelected: (selected) {
                      setState(() {
                        _selectedView = view;
                      });
                      Navigator.pop(context);
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
                  _selectedSort = 'Nama A-Z';
                  _selectedView = 'Grid';
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
    final totalBarang = _allBarang.length;
    final tersedia = _allBarang.where((b) => b.jumlahBarang > 0).length;
    final stokRendah = _allBarang.where((b) => b.jumlahBarang > 0 && b.jumlahBarang <= 5).length;
    final habis = _allBarang.where((b) => b.jumlahBarang == 0).length;
    final totalStok = _allBarang.fold(0, (sum, b) => sum + b.jumlahBarang);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Statistik Barang', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatCard('Total Barang', totalBarang.toString(), Icons.inventory, Colors.blue),
              const SizedBox(height: 12),
              _buildStatCard('Tersedia', tersedia.toString(), Icons.check_circle, Colors.green),
              const SizedBox(height: 12),
              _buildStatCard('Stok Rendah', stokRendah.toString(), Icons.warning, Colors.orange),
              const SizedBox(height: 12),
              _buildStatCard('Habis', habis.toString(), Icons.cancel, Colors.red),
              const SizedBox(height: 12),
              _buildStatCard('Total Stok', totalStok.toString(), Icons.storage, Colors.purple),
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
                  hintText: 'Cari barang...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('Daftar Barang'),
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
                  if (_allBarang.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total',
                              _allBarang.length.toString(),
                              Icons.inventory,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Tersedia',
                              _allBarang.where((b) => b.jumlahBarang > 0).length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Habis',
                              _allBarang.where((b) => b.jumlahBarang == 0).length.toString(),
                              Icons.cancel,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Content
                  Expanded(
                    child: _filteredBarang.isEmpty
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
                                      : 'Tidak ada barang',
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
                              onRefresh: _loadBarang,
                              child: _selectedView == 'Grid'
                                  ? _buildGridView()
                                  : _buildListView(),
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

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredBarang.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final barang = _filteredBarang[index];
        return _buildBarangCard(barang, isGrid: true);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredBarang.length,
      itemBuilder: (context, index) {
        final barang = _filteredBarang[index];
        return _buildBarangCard(barang, isGrid: false);
      },
    );
  }

  Widget _buildBarangCard(Barang barang, {required bool isGrid}) {
    final stockColor = barang.jumlahBarang > 5
        ? Colors.green
        : barang.jumlahBarang > 0
            ? Colors.orange
            : Colors.red;

    final stockIcon = barang.jumlahBarang > 5
        ? Icons.check_circle
        : barang.jumlahBarang > 0
            ? Icons.warning
            : Icons.cancel;

    if (isGrid) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BarangDetailPage(barang: barang),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: barang.foto.isNotEmpty
                        ? Image.network(
                            'http://127.0.0.1:8000/storage/${barang.foto}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400),
                                ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade400),
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barang.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(stockIcon, size: 16, color: stockColor),
                          const SizedBox(width: 4),
                          Text(
                            '${barang.jumlahBarang}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BarangDetailPage(barang: barang),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: barang.foto.isNotEmpty
                        ? Image.network(
                            'http://127.0.0.1:8000/storage/${barang.foto}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.broken_image, size: 30, color: Colors.grey.shade400),
                                ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey.shade400),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barang.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(stockIcon, size: 18, color: stockColor),
                          const SizedBox(width: 6),
                          Text(
                            'Stok: ${barang.jumlahBarang}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      );
    }
  }
}
