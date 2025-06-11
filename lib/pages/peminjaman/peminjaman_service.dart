import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisfo_sarpas/pages/peminjaman/peminjaman_model.dart';

class PeminjamanService {
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

  Future<bool> pinjamBarang(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();

      // Pastikan user_id ada dalam data
      if (userId != null) {
        data['user_id'] = userId;
      }

      // Pastikan status default adalah 'menunggu' sesuai API screenshot
      data['status'] = 'menunggu';

      print('Data yang dikirim ke API: $data');

      final response = await http.post(
        Uri.parse('$baseUrl/peminjaman'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Gagal pinjam: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error pinjam barang: $e');
      return false;
    }
  }

  Future<List<Peminjaman>> fetchRiwayatPeminjaman() async {
    final userId = await _getUserId();
    if (userId == null) {
      print('User ID tidak ditemukan');
      return [];
    }
    print('Fetching riwayat peminjaman for user ID: $userId');

    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(
        Uri.parse('$baseUrl/peminjaman'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData is Map && jsonData.containsKey('data')) {
          final List<dynamic> jsonList = jsonData['data'];
          print('Found ${jsonList.length} peminjaman records');
          return jsonList.map((json) => Peminjaman.fromJson(json)).toList();
        } else if (jsonData is List) {
          print('Found ${jsonData.length} peminjaman records (list format)');
          return jsonData.map((json) => Peminjaman.fromJson(json)).toList();
        } else {
          print('Unexpected response format');
        }
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      print('Error fetching riwayat peminjaman: $e');
      return [];
    }
  }
}
