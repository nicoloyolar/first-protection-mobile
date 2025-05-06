// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:first_protection/constants/messages.dart';
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

  void _login() {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacementNamed(context, '/select');
    });
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
                  SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: "Usuario", 
                      hintStyle: TextStyle(
                        color: Color(0xFFFF6C2C), 
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white, 
                          width: 2.0,
                        ),
                      ),
                      prefixIcon: Icon(Icons.person, color: Color(0xFFFF6C2C)),
                    ),
                    style: TextStyle(
                      color: Colors.white, 
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Contraseña", 
                      hintStyle: TextStyle(
                        color: Color(0xFFFF6C2C), 
                      ),
                      filled: true,
                      fillColor: Colors.transparent, 
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white, 
                          width: 2.0,
                        ),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFFFF6C2C)),
                    ),
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity, 
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF6C2C), 
                              foregroundColor: Colors.black, 
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
