import 'dart:convert';
import 'package:http/http.dart' as http;
import 'barang_model.dart';

class BarangService {
  final String baseUrl = 'http://127.0.0.1:8000/api';

  Future<List<Barang>> fetchBarang() async {
  final response = await http.get(Uri.parse('$baseUrl/barang'));

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    final List<dynamic> jsonList = jsonData['data'];
    return jsonList.map((json) => Barang.fromJson(json)).toList();
  } else {
    throw Exception('Gagal memuat data barang');
  }
}

}
