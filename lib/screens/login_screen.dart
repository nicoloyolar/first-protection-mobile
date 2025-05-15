// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:first_protection/constants/messages.dart';
import 'package:first_protection/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_protection/widgets/custom_password_reset_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance; 

  final TextEditingController _resetEmailController = TextEditingController();

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (_) => CustomPasswordResetPopup(
        emailController: _resetEmailController,
        onCancel: () {
          Navigator.of(context).pop();
        },
        onConfirm: _sendPasswordResetEmail,
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _resetEmailController.text.trim();

    if (email.isEmpty) {
      Navigator.of(context).pop();
      _showCustomAlert("Debes ingresar un correo electrónico.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Navigator.of(context).pop();
      _showCustomAlert("Te hemos enviado un correo para restablecer tu contraseña.");
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      _showCustomAlert('Error: ${e.message}');
    } catch (e) {
      Navigator.of(context).pop();
      _showCustomAlert('Error inesperado: $e');
    }
  }

  void _showCustomAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => CustomAlert(
        message: message,
        showCancelButton: false,
      ),
    );
  }

  Future<void> _login() async {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text;

    if (user.isEmpty || pass.isEmpty) {
      _showCustomAlert("Debes completar todos los campos.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: user,
        password: pass,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushReplacementNamed(context, '/select');

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showCustomAlert('Usuario no encontrado.');
      } else if (e.code == 'wrong-password') {
        _showCustomAlert('Contraseña incorrecta.');
      } else {
        _showCustomAlert('Error: ${e.message}');
      }
    } catch (e) {
      _showCustomAlert('Error inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                      decoration: _inputDecoration(hintText: "Correo electrónico", icon: Icons.person),
                      keyboardType: TextInputType.emailAddress,
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
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          "¿No tienes cuenta? Crear nueva cuenta",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: _showPasswordResetDialog,
                        child: const Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(color: Colors.white),
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
