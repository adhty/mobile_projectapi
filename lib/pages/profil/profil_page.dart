import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profil_service.dart';
import 'profil_model.dart';
import '../peminjaman/peminjaman_service.dart';
import '../pengembalian/pengembalian_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final ProfileService _service = ProfileService();
  final PeminjamanService _peminjamanService = PeminjamanService();
  final PengembalianService _pengembalianService = PengembalianService();

  bool _isLoading = true;
  bool _isLoadingStats = false;
  UserProfile? _userProfile;
  String _errorMessage = '';

  // Statistics
  int _totalPeminjaman = 0;
  int _totalPengembalian = 0;
  int _peminjamanAktif = 0;

  // Edit profile controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadStatistics();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final profile = await _service.fetchUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });

      // Initialize controllers with current data
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone ?? '';
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Load peminjaman statistics
      final riwayatPeminjaman = await _peminjamanService.fetchRiwayatPeminjaman();
      final peminjamanAktif = await _pengembalianService.fetchPeminjamanAktif();
      final riwayatPengembalian = await _pengembalianService.fetchRiwayatPengembalian();

      setState(() {
        _totalPeminjaman = riwayatPeminjaman.length;
        _totalPengembalian = riwayatPengembalian.length;
        _peminjamanAktif = peminjamanAktif.length;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      print('Error loading statistics: $e');
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              
              // Tampilkan loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Tambahkan timeout untuk logout
              bool success = false;
              try {
                success = await _service.logout().timeout(
                  const Duration(seconds: 2),
                  onTimeout: () {
                    print('Logout timeout');
                    return false;
                  },
                );
              } catch (e) {
                print('Error during logout: $e');
              }
              
              if (!mounted) return;
              
              // Tutup loading
              Navigator.pop(context);
              
              if (success) {
                // Kembali ke halaman login jika berhasil
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              } else {
                // Jika gagal, tetap logout secara lokal
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Hapus semua data lokal
                
                // Kembali ke halaman login jika berhasil
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logout lokal berhasil, tapi server tidak merespons')),
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik Aktivitas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('Total Peminjaman', _totalPeminjaman, Icons.arrow_circle_down, Colors.blue),
            _buildStatItem('Total Pengembalian', _totalPengembalian, Icons.arrow_circle_up, Colors.green),
            _buildStatItem('Peminjaman Aktif', _peminjamanAktif, Icons.pending, Colors.orange),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        title: const Text('Profil Saya'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatistics,
            tooltip: 'Statistik',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_userProfile == null) {
      return const Center(child: Text('Data profil tidak tersedia'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Column(
            children: [
              // Header dengan avatar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: _userProfile!.avatar != null && _userProfile!.avatar!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  _userProfile!.avatarUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                              loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading avatar: $error');
                                    print('Avatar URL: ${_userProfile!.avatarUrl}');
                                    return const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.blue,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.blue,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userProfile!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _userProfile!.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Menu Aksi
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.history, color: Colors.blue.shade700),
                          ),
                          title: const Text('Riwayat Aktivitas'),
                          subtitle: const Text('Lihat riwayat peminjaman dan pengembalian'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pushNamed(context, '/riwayat');
                          },
                        ),
                        const Divider(),
                        const Divider(),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(Icons.analytics, color: Colors.orange.shade700),
                          ),
                          title: const Text('Statistik'),
                          subtitle: const Text('Lihat statistik aktivitas Anda'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _showStatistics,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Statistics Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistik Singkat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingStats)
                          const Center(child: CircularProgressIndicator())
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickStatCard(
                                  'Peminjaman',
                                  _totalPeminjaman.toString(),
                                  Icons.arrow_circle_down,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickStatCard(
                                  'Pengembalian',
                                  _totalPengembalian.toString(),
                                  Icons.arrow_circle_up,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickStatCard(
                                  'Aktif',
                                  _peminjamanAktif.toString(),
                                  Icons.pending,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Informasi profil
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Pribadi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildInfoItem(
                          Icons.person,
                          'Nama',
                          _userProfile!.name,
                        ),
                        _buildInfoItem(
                          Icons.email,
                          'Email',
                          _userProfile!.email,
                        ),
                        _buildInfoItem(
                          Icons.badge,
                          'Role',
                          _userProfile!.role.toUpperCase(),
                        ),
                        _buildInfoItem(
                          Icons.calendar_today,
                          'Bergabung Sejak',
                          _userProfile!.createdAt != null
                              ? _formatDate(_userProfile!.createdAt!)
                              : 'Tidak diketahui'
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}




