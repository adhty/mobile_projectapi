import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pengembalian_model.dart';
import '../peminjaman/peminjaman_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../barang/barang_service.dart';
import '../barang/barang_model.dart';

class PengembalianService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Peminjaman>> fetchPeminjamanAktif() async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception('User ID tidak ditemukan');
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/peminjaman'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map && jsonData.containsKey('data')) {
          final List<dynamic> jsonList = jsonData['data'];
          return jsonList.map((json) => Peminjaman.fromJson(json)).toList();
        } else if (jsonData is List) {
          return jsonData.map((json) => Peminjaman.fromJson(json)).toList();
        } else {
          throw Exception('Format respons API tidak sesuai');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Tidak terautentikasi. Silakan login kembali.');
      } else {
        throw Exception('Gagal memuat data peminjaman aktif: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching peminjaman aktif: $e');
    }
  }

  Future<void> updateBarangNames(List<Peminjaman> peminjamanList) async {
    try {
      final barangService = BarangService();
      final allBarang = await barangService.fetchBarang();

      for (var peminjaman in peminjamanList) {
        if (peminjaman.namaBarang == 'Barang tidak diketahui') {
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
          if (barang.id > 0) {
            peminjaman.namaBarang = barang.nama;
          }
        }
      }
    } catch (e) {
      print('Error updating barang names: $e');
    }
  }

  Future<bool> kembalikanBarang(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();

      final formattedData = {
        'peminjaman_id': data['peminjaman_id'],
        'tanggal_pengembalian': data['tanggal_pengembalian'],
        'kondisi_barang': data['kondisi_barang'],
        'catatan': data['catatan'] ?? '',
        'status': 'menunggu',
        'jumlah_kembali': data['jumlah_kembali'],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/pengembalian'),
        headers: headers,
        body: jsonEncode(formattedData),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error kembalikan barang: $e');
      return false;
    }
  }

  Future<List<Pengembalian>> fetchRiwayatPengembalian() async {
    final userId = await _getUserId();
    if (userId == null) return [];

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/pengembalian/user/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map && jsonData.containsKey('data')) {
          final List<dynamic> jsonList = jsonData['data'];
          return jsonList.map((json) => Pengembalian.fromJson(json)).toList();
        } else if (jsonData is List) {
          return jsonData.map((json) => Pengembalian.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching riwayat pengembalian: $e');
      return [];
    }
  }

  Future<bool> updateStatusPengembalian(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();

      final formattedData = {
        'peminjaman_id': data['peminjaman_id'],
        'status': data['status'],
        'catatan': data['catatan'] ?? '',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/pengembalian/status'),
        headers: headers,
        body: jsonEncode(formattedData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error update status pengembalian: $e');
      return false;
    }
  }
}

