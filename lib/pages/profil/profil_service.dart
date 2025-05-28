import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'profil_model.dart';

class ProfileService {
  // Ubah baseUrl sesuai dengan endpoint API yang benar
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

  // Mengambil data profil pengguna
  Future<UserProfile> fetchUserProfile() async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      
      print('Token: $token');
      print('User ID: $userId');
      
      if (token == null || userId == null) {
        throw Exception('Tidak terautentikasi. Silakan login kembali.');
      }
      
      // Coba beberapa endpoint yang mungkin
      final endpoints = [
        '$baseUrl/users/$userId',
        '$baseUrl/user/$userId',
        '$baseUrl/profile',
        '$baseUrl/me'
      ];
      
      http.Response? response;
      String? usedEndpoint;
      
      for (final endpoint in endpoints) {
        try {
          print('Trying endpoint: $endpoint');
          final tempResponse = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          
          print('Response from $endpoint: ${tempResponse.statusCode}');
          
          if (tempResponse.statusCode == 200) {
            response = tempResponse;
            usedEndpoint = endpoint;
            break;
          }
        } catch (e) {
          print('Error trying $endpoint: $e');
        }
      }
      
      if (response == null) {
        throw Exception('Tidak dapat mengakses API profil. Silakan coba lagi.');
      }
      
      print('Successfully fetched from: $usedEndpoint');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final jsonData = jsonDecode(response.body);
      
      // Coba berbagai kemungkinan struktur respons
      if (jsonData is Map) {
        if (jsonData.containsKey('data') && jsonData['data'] is Map) {
          return UserProfile.fromJson(jsonData['data']);
        } else if (jsonData.containsKey('user') && jsonData['user'] is Map) {
          return UserProfile.fromJson(jsonData['user']);
        } else {
          // Coba parse langsung
          return UserProfile.fromJson(Map<String, dynamic>.from(jsonData));
        }
      } else {
        throw Exception('Format respons API tidak sesuai');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      throw Exception('Gagal memuat data profil: $e');
    }
  }

  // Update profil pengguna
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      
      if (token == null || userId == null) {
        throw Exception('Tidak terautentikasi. Silakan login kembali.');
      }
      
      // Tambahkan log untuk melihat data yang dikirim
      print('Data yang akan diupdate: $data');
      
      // Coba endpoint yang lebih spesifik dulu
      final endpoint = '$baseUrl/users/$userId';
      print('Trying to update profile at: $endpoint');
      
      final response = await http.put(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');
      
      // Terima status 200 dan 201 sebagai sukses
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        // Jika tidak ada token, hapus saja data lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user_id');
        return true;
      }
      
      // Coba beberapa endpoint yang mungkin
      final endpoints = [
        '$baseUrl/logout',
        '$baseUrl/auth/logout'
      ];
      
      http.Response? response;
      
      for (final endpoint in endpoints) {
        try {
          print('Trying to logout at: $endpoint');
          final tempResponse = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          
          print('Logout response from $endpoint: ${tempResponse.statusCode}');
          
          if (tempResponse.statusCode == 200) {
            response = tempResponse;
            break;
          }
        } catch (e) {
          print('Error trying to logout at $endpoint: $e');
        }
      }
      
      // Hapus data lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_id');
      
      return true; // Anggap berhasil logout meskipun API error
    } catch (e) {
      print('Error during logout: $e');
      
      // Hapus data lokal meskipun terjadi error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_id');
      
      return true; // Anggap berhasil logout meskipun API error
    }
  }
}






