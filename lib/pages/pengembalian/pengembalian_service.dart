import 'dart:convert';
import 'package:http/http.dart' as http;
import '../peminjaman/peminjaman_model.dart';

class PengembalianService {
  final String baseUrl = 'http://127.0.0.1:8000/api';

  // Fetch peminjaman yang belum dikembalikan oleh user
  Future<List<Peminjaman>> fetchPeminjamanAktif(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/peminjaman/user/$userId/aktif'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        // Check if data exists and is a list
        if (jsonData['data'] != null && jsonData['data'] is List) {
          final List<dynamic> jsonList = jsonData['data'];
          return jsonList.map((json) => Peminjaman.fromJson(json)).toList();
        } else {
          // Return empty list if no data
          return [];
        }
      } else {
        throw Exception('Gagal memuat data peminjaman aktif: ${response.body}');
      }
    } catch (e) {
      print('Error in fetchPeminjamanAktif: $e');
      throw Exception('Gagal memuat data peminjaman aktif: $e');
    }
  }

  // Submit pengembalian barang
  Future<bool> kembalikanBarang(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pengembalian'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Gagal mengembalikan: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error in kembalikanBarang: $e');
      return false;
    }
  }
}
