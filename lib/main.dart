import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/core/theme/app_colors.dart';
import 'src/apps/client_mobile/ui/mobile_login_screen.dart';
import 'src/apps/admin_web/ui/admin_web_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();

  runApp(const FirstProtectionMasterApp());
}

class FirstProtectionMasterApp extends StatelessWidget {
  const FirstProtectionMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Protection',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundBlack,
        primaryColor: AppColors.primaryOrange,
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.textGrey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
          ),
          labelStyle: TextStyle(color: AppColors.textGrey),
        ),
      ),

      home: kIsWeb ? const AdminLoginScreen() : const LoginScreen(),
    );
  }
}