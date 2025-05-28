import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
}
