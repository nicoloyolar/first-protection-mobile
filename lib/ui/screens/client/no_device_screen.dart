// ignore_for_file: deprecated_member_use, empty_catches

import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_protection/src/apps/client_mobile/ui/vincular_vehiculo_screen.dart';
import 'package:first_protection/src/core/theme/app_colors.dart';
import 'package:first_protection/src/ui/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoDeviceScreen extends StatelessWidget {
  const NoDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)), 
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 110,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                "¡BIENVENIDO A\nFIRST PROTECTION!",
                textAlign: TextAlign.center,
                style: GoogleFonts.oswald(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                "Tu cuenta está activa, pero aún no tienes ningún sistema de seguridad vinculado.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VincularVehiculoScreen()),
                    );
                  },
                  child: const Text(
                    "VINCULAR MI DISPOSITIVO",
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => _mostrarConfirmacionSalida(context),
                  child: const Text(
                    "CERRAR SESIÓN",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarConfirmacionSalida(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return FirstProtectionDialog(
          titulo: "¿Cerrar Sesión?",
          mensaje: "Tendrás que volver a ingresar tus credenciales para acceder a tu protección.",
          textoConfirmar: "SALIR",
          onConfirmar: () async {
            try {
              await FirebaseAuth.instance.signOut();
              
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            } catch (e) {
            }
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack, 
          ),
          child: child,
        );
      },
    );
  }

  
}