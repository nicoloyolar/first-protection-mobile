import 'package:first_protection/screens/splash_screen.dart';
import 'package:first_protection/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:first_protection/screens/login_screen.dart';
import 'package:first_protection/screens/select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),       
        '/login': (context) => const LoginScreen(),   
        '/select': (context) => const AdminDeviceSelectionScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}
