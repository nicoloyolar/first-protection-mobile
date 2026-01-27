import 'package:first_protection/core/controllers/vehiculo_controller.dart';
import 'package:first_protection/firebase_options.dart';
import 'package:first_protection/ui/screens/home_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/core/theme/app_colors.dart';
import 'src/apps/client_mobile/ui/mobile_login_screen.dart';
import 'src/apps/admin_web/ui/admin_web_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehiculoController()),
      ],
      child: const FirstProtectionMasterApp(),
    ),
  );
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

      home: kIsWeb 
        ? const AdminLoginScreen() 
        : StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
                );
              }

              if (snapshot.hasData) {
                return const HomeRouter(); 
              }

              return const LoginScreen();
            },
          ),
    );
    
  }
}