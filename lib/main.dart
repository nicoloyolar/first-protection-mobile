import 'package:first_protection/screens/user_registration.dart';
import 'package:flutter/material.dart';
import 'package:first_protection/screens/dashboard_screen.dart';
import 'package:first_protection/screens/event_detail_screen.dart';
import 'package:first_protection/screens/history_screen.dart';
import 'package:first_protection/screens/login_screen.dart';
import 'package:first_protection/screens/select_screen.dart';
import 'package:first_protection/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/'                 : (context) => LoginScreen(),
        '/dashboard'        : (context) => DashboardScreen(),
        '/select'           : (context) => AdminDeviceSelectionScreen(),
        '/history'          : (context) => HistoryScreen(),
        '/settings'         : (context) => SettingsScreen(),
        '/eventDetail'      : (context) => EventDetailScreen(event: ModalRoute.of(context)!.settings.arguments as Map<String, String>),
        '/userRegistration' : (context) => UserRegistrationScreen(),
      },
    );
  }
}