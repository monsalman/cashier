import 'package:cashier/main.dart';
import 'package:cashier/view/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rolesController = TextEditingController();

  final _supabase = Supabase.instance.client;

  bool _obscureText = true;

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

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await _supabase.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response.user != null) {
          await _supabase.from('tbl_user').insert({
            'username_user': _usernameController.text,
            'email_user': _emailController.text,
            'roles_user': _rolesController.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
          );

          Navigator.push(context,MaterialPageRoute(builder: (context) => HomePage()),);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                  Icon(
                    Icons.app_registration,
                    size: 100,
                    color: Colors.white,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Daftar Akun Baru',
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
                              controller: _usernameController,
                              decoration: _inputDecoration('Username', Icons.person, 'Masukkan username Anda'),
                              style: TextStyle(color: Warna),
                              cursorColor: Warna,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Mohon masukkan username';
                                }
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                              ],
                            ),
                            SizedBox(height: 16),
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
                                if (value.length < 6) {
                                  return 'Password harus minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _rolesController.text.isEmpty ? null : _rolesController.text,
                              decoration: _inputDecoration('Role', Icons.work, 'Pilih role Anda'),
                              items: ['admin', 'petugas', 'user']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(color: Warna)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _rolesController.text = newValue!;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Mohon pilih role';
                                }
                                return null;
                              },
                              style: TextStyle(color: Warna),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.arrow_drop_down, color: Warna),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _register,
                              child: Text('Daftar'),
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
                  SizedBox(
                    width: 200, // Reduced width
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Kembali ke Homepage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Warna,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }
}