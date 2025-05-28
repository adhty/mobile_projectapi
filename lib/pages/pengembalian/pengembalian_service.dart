import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pengembalian_model.dart';
import '../peminjaman/peminjaman_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../barang/barang_service.dart';
import '../barang/barang_model.dart';

class PengembalianService {
  final String baseUrl = 'http://127.0.0.1:8000/api';

  // Mendapatkan token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Mendapatkan user ID dari SharedPreferences
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Mengambil daftar peminjaman yang belum dikembalikan
  Future<List<Peminjaman>> fetchPeminjamanAktif() async {
    try {
      // Dapatkan token dan user ID
      final token = await _getToken();
      final userId = await _getUserId() ?? 1; // Default ke user ID 1 jika tidak ada

      // Buat request dengan header Authorization
      final response = await http.get(
        Uri.parse('$baseUrl/peminjaman/user/$userId/aktif'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Fetching from: $baseUrl/peminjaman/user/$userId/aktif');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Periksa struktur respons
        if (jsonData is Map && jsonData.containsKey('data')) {
          final List<dynamic> jsonList = jsonData['data'];
          return jsonList.map((json) => Peminjaman.fromJson(json)).toList();
        } else if (jsonData is List) {
          // Jika API langsung mengembalikan array
          return jsonData.map((json) => Peminjaman.fromJson(json)).toList();
        } else {
          throw Exception('Format respons API tidak sesuai');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Tidak terautentikasi. Silakan login kembali.');
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Gagal memuat data peminjaman aktif: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching peminjaman aktif: $e');
      throw Exception('Gagal memuat data peminjaman aktif: $e');
    }
  }

  // Fungsi untuk mengambil nama barang berdasarkan ID
  Future<void> updateBarangNames(List<Peminjaman> peminjamanList) async {
    final BarangService barangService = BarangService();

    try {
      // Ambil semua barang
      final List<Barang> allBarang = await barangService.fetchBarang();
      print('Berhasil mengambil ${allBarang.length} barang');

      // Update nama barang pada setiap peminjaman
      for (var peminjaman in peminjamanList) {
        if (peminjaman.namaBarang == 'Barang tidak diketahui') {
          // Cari barang dengan ID yang sesuai
          final barang = allBarang.firstWhere(
            (b) => b.id == peminjaman.idBarang,
            orElse: () => Barang(
              id: 0,
              nama: 'Barang tidak diketahui',
              jumlahBarang: 0,
              foto: '',
              idKategori: 0,
            ),
          );

          // Update nama barang
          if (barang.id > 0) {
            peminjaman.namaBarang = barang.nama;
            print('Updated nama barang untuk ID ${peminjaman.idBarang}: ${barang.nama}');
          }
        }
      }
    } catch (e) {
      print('Error updating barang names: $e');
    }
  }

  // Mengirim permintaan pengembalian
  Future<bool> kembalikanBarang(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();

      // Pastikan semua field yang dibutuhkan ada
      print('Data yang dikirim: $data');

      // Format data sesuai dengan yang diharapkan backend (sesuai screenshot API)
      final formattedData = {
        'peminjaman_id': data['peminjaman_id'],
        'tanggal_pengembalian': data['tanggal_pengembalian'],
        'kondisi_barang': data['kondisi_barang'],
        'catatan': data['catatan'] ?? '',
        'status': 'menunggu',
        'jumlah_kembali': data['jumlah_kembali'],
      };

      print('Formatted data: $formattedData');

      final response = await http.post(
        Uri.parse('$baseUrl/pengembalian'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(formattedData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Gagal mengembalikan: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error kembalikan barang: $e');
      return false;
    }
  }

  // Mengambil riwayat pengembalian
  Future<List<Pengembalian>> fetchRiwayatPengembalian() async {
    try {
      final token = await _getToken();
      final userId = await _getUserId() ?? 1;

      final response = await http.get(
        Uri.parse('$baseUrl/pengembalian/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map && jsonData.containsKey('data')) {
          final List<dynamic> jsonList = jsonData['data'];
          return jsonList.map((json) => Pengembalian.fromJson(json)).toList();
        } else if (jsonData is List) {
          return jsonData.map((json) => Pengembalian.fromJson(json)).toList();
        } else {
          throw Exception('Format respons API tidak sesuai');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Tidak terautentikasi. Silakan login kembali.');
      } else {
        throw Exception('Gagal memuat riwayat pengembalian');
      }
    } catch (e) {
      print('Error fetching riwayat pengembalian: $e');
      throw Exception('Gagal memuat riwayat pengembalian: $e');
    }
  }
}















