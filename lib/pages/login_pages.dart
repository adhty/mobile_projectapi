import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      // Print respons untuk debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cek struktur respons
        print('Response structure: ${data.runtimeType}');
        print('Response keys: ${data is Map ? data.keys.toList() : "Not a map"}');
        
        // Coba dapatkan token dengan berbagai kemungkinan struktur
        String? token;
        if (data is Map) {
          // Coba beberapa kemungkinan key untuk token
          if (data.containsKey('access_token')) {
            token = data['access_token'];
          } else if (data.containsKey('token')) {
            token = data['token'];
          } else if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('token')) {
            token = data['data']['token'];
          }
        }
        
        if (token == null) {
          print('Token tidak ditemukan dalam respons');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login berhasil tapi token tidak ditemukan')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        print('Login berhasil! Token: $token');

        // Simpan token dan user_id ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        
        // Coba dapatkan user_id dari berbagai kemungkinan struktur
        int? userId;
        if (data is Map) {
          if (data.containsKey('user') && data['user'] is Map && data['user'].containsKey('id')) {
            userId = data['user']['id'];
          } else if (data.containsKey('data') && data['data'] is Map && 
                    data['data'].containsKey('user') && data['data']['user'] is Map && 
                    data['data']['user'].containsKey('id')) {
            userId = data['data']['user']['id'];
          } else if (data.containsKey('id')) {
            userId = data['id'];
          }
        }
        
        if (userId != null) {
          await prefs.setInt('user_id', userId);
          print('User ID saved: $userId');
        } else {
          print('User ID tidak ditemukan dalam respons');
        }

        // Tampilkan alert dialog setelah login berhasil
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                const Text('Login Berhasil'),
              ],
            ),
            content: const Text('Selamat datang di Sistem Informasi Sarana Prasarana SMK TARUNA BHAKTI'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pushReplacementNamed(context, '/home'); // Navigasi ke home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Handle error
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          print('Error parsing response: $e');
        }

        final errorMessage = errorData['message'] ?? 'Login gagal: ${response.statusCode}';
        print('Login gagal: $errorMessage');

        // Tampilkan alert dialog untuk error login
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                const Text('Login Gagal'),
              ],
            ),
            content: Text(_getErrorMessage(errorMessage, response.statusCode)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error during login: $e');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              const Text('Kesalahan Koneksi'),
            ],
          ),
          content: Text('Terjadi kesalahan saat menghubungi server. Silakan periksa koneksi internet Anda dan coba lagi.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method untuk mendapatkan pesan error yang user-friendly
  String _getErrorMessage(String errorMessage, int statusCode) {
    // Cek berbagai kemungkinan pesan error untuk password salah
    if (errorMessage.toLowerCase().contains('password') ||
        errorMessage.toLowerCase().contains('credentials') ||
        errorMessage.toLowerCase().contains('unauthorized') ||
        statusCode == 401) {
      return 'Email atau password yang Anda masukkan salah. Silakan periksa kembali dan coba lagi.';
    }

    // Cek untuk email tidak ditemukan
    if (errorMessage.toLowerCase().contains('email') ||
        errorMessage.toLowerCase().contains('user not found') ||
        statusCode == 404) {
      return 'Email tidak terdaftar dalam sistem. Silakan periksa kembali email Anda.';
    }

    // Cek untuk validasi input
    if (errorMessage.toLowerCase().contains('validation') ||
        errorMessage.toLowerCase().contains('required') ||
        statusCode == 422) {
      return 'Data yang Anda masukkan tidak valid. Pastikan email dan password telah diisi dengan benar.';
    }

    // Cek untuk server error
    if (statusCode >= 500) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi dalam beberapa saat.';
    }

    // Default error message
    return 'Login gagal. Silakan periksa email dan password Anda, lalu coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 12, 
                  shadowColor: Colors.black38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo dengan efek shadow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.jpg',
                              height: 120,
                              width: 120,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'SMK TARUNA BHAKTI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'Sistem Informasi Sarana Prasarana',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Progress indicator
                        LinearProgressIndicator(
                          value: _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty ? 1.0 : 
                                 _emailController.text.isNotEmpty || _passwordController.text.isNotEmpty ? 0.5 : 0.1,
                          backgroundColor: Colors.grey.shade200,
                          color: _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty ? 
                                 Colors.green : _emailController.text.isNotEmpty || _passwordController.text.isNotEmpty ? 
                                 Colors.orange : Colors.red,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Masukkan email Anda',
                            prefixIcon: Icon(Icons.email, color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          onChanged: (_) => setState(() {}),
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Masukkan password Anda',
                            prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.blue.shade700,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 3,
                                    shadowColor: Colors.blue.shade200,
                                  ),
                                  child: const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
