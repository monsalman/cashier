import 'package:cashier/main.dart';
import 'package:cashier/view/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  final supabase = Supabase.instance.client;

  InputDecoration _inputDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Warna.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: Warna),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Warna, width: 2),
      ),
      labelStyle: TextStyle(color: Warna),
      floatingLabelStyle: TextStyle(color: Warna),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (response.user != null) {
          // Login berhasil, navigasi ke halaman utama
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
        } else {
          // Login gagal
          throw Exception('Login gagal');
        }
      } catch (e) {
        // Tampilkan pesan error jika login gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email atau password salah!!')),
        );
      } finally {
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
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Warna],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/casir.png',
                    width: 150,
                    height: 150,
                  ),
                  Text(
                    'Cashier App',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 48),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration('Email', Icons.email, 'Masukkan email Anda'),
                              style: TextStyle(color: Warna),
                              cursorColor: Warna,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Mohon masukkan email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Masukkan email yang valid';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: _inputDecoration('Password', Icons.lock, 'Masukkan password Anda')
                                .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText ? Icons.visibility : Icons.visibility_off,
                                      color: Warna,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                ),
                              style: TextStyle(color: Warna),
                              cursorColor: Warna,
                              obscureText: _obscureText,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Mohon masukkan password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text('Login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Warna,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}