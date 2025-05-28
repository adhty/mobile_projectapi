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

        // Arahkan ke halaman Home
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
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
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: $errorMessage')),
        );
      }
    } catch (e) {
      print('Error during login: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              Colors.blue.shade800,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo SMK Taruna Bhakti
                        Image.asset(
                          'assets/logo.jpg',
                          height: 120,
                          width: 120,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SMK TARUNA BHAKTI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sistem Informasi Sarana Prasarana',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
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
