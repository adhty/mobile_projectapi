import 'dart:convert';
import 'package:http/http.dart' as http;

class PeminjamanService {
  final String baseUrl = 'http://127.0.0.1:8000/api';

  Future<bool> pinjamBarang(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/peminjaman'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('Gagal pinjam: ${response.body}');
      return false;
    }
  }
}
