// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:first_protection/constants/messages.dart';
import 'package:first_protection/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; 

  void _showCustomAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => CustomAlert(
        message: message,
        showCancelButton: false, 
      ),
    );
  }

  void _login() {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text;

    if (user.isEmpty || pass.isEmpty) {
      _showCustomAlert("Debes completar todos los campos.");
      return;
    }

    if (user != 'admin' || pass != 'admin') {
      _showCustomAlert("Usuario o contraseña incorrectos.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacementNamed(context, '/select');
    });
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFFF6C2C)),
      filled: true,
      fillColor: Colors.transparent,
      prefixIcon: Icon(icon, color: const Color(0xFFFF6C2C)),
      suffixIcon: suffixIcon,
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/carbonfiber.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo-first-protection.jpeg',
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: const TextSelectionThemeData(
                        cursorColor: Colors.white,
                      ),
                    ),
                    child: TextField(
                      controller: _usernameController,
                      decoration: _inputDecoration(hintText: "Usuario", icon: Icons.person),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: const TextSelectionThemeData(
                        cursorColor: Colors.white,
                      ),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hintText: "Contraseña",
                        icon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFFFF6C2C),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6C2C),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(Messages.loginButton),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
