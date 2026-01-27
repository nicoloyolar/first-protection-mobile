// ignore_for_file: deprecated_member_use

import 'dart:math'; // <--- 1. IMPORTANTE PARA GENERAR EL TOKEN
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_protection/src/core/theme/app_colors.dart';
import 'package:first_protection/src/ui/widgets/custom_notification.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/controllers/vehiculo_controller.dart';

class VincularVehiculoScreen extends StatefulWidget {
  const VincularVehiculoScreen({super.key});

  @override
  State<VincularVehiculoScreen> createState() => _VincularVehiculoScreenState();
}

class _VincularVehiculoScreenState extends State<VincularVehiculoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _idDispositivoController = TextEditingController();
  final _aliasController = TextEditingController();
  final _patenteController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();

  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _generarTokenDispositivo();
  }

  void _generarTokenDispositivo() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    String randomCode = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    
    _idDispositivoController.text = "GPS-$randomCode";
  }

  @override
  void dispose() {
    _idDispositivoController.dispose();
    _aliasController.dispose();
    _patenteController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  void _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _procesando = true);

    final vCtrl = Provider.of<VehiculoController>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final patenteLimpia = _patenteController.text.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
      try {
        bool exito = await vCtrl.vincularVehiculo(
          idUsuario: user.uid,
          idDispositivo: _idDispositivoController.text.trim(), 
          alias: _aliasController.text.trim(),
          patente: patenteLimpia,
          marca: _marcaController.text.trim(),
          modelo: _modeloController.text.trim(),
        );

        if (mounted) {
          if (exito) {
            FirstProtectionNotification.show(
              context: context,
              message: "¡Vehículo vinculado con éxito!",
              type: NotificationType.success,
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          } else {
            FirstProtectionNotification.show(
              context: context,
              message: "Error: Este dispositivo ya está en uso.",
              type: NotificationType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          FirstProtectionNotification.show(
            context: context,
            message: "Error de conexión con el servidor.",
            type: NotificationType.error,
          );
        }
      }
    }
    if (mounted) setState(() => _procesando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ACTIVAR ESCUDO",
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildHeaderIcon(),
                        const SizedBox(height: 40),
                        
                        _buildSectionTitle("IDENTIFICACIÓN"),
                        
                        _buildPremiumInput(
                          label: "ID Dispositivo (Auto-Asignado)",
                          controller: _idDispositivoController,
                          icon: Icons.vpn_key_outlined, 
                          isPrimary: true,
                          readOnly: true, 
                          hint: "Generando...",
                        ),
                        
                        const SizedBox(height: 25),
                        _buildSectionTitle("DETALLES DEL VEHÍCULO"),
                        
                        _buildPremiumInput(
                          label: "Alias / Nombre",
                          controller: _aliasController,
                          icon: Icons.bookmark_added_outlined,
                          hint: "Ej: Mi Camioneta",
                        ),
                        const SizedBox(height: 15),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildPremiumInput(
                                label: "Patente",
                                controller: _patenteController,
                                icon: Icons.badge_outlined,
                                hint: "AAAA10",
                                validator: _validarPatente, 
                                onChanged: (val) {
                                  _patenteController.value = _patenteController.value.copyWith(
                                    text: val.toUpperCase(),
                                    selection: TextSelection.collapsed(offset: val.length),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildPremiumInput(
                                label: "Marca",
                                controller: _marcaController,
                                icon: Icons.factory_outlined,
                                hint: "Toyota",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        _buildPremiumInput(
                          label: "Modelo",
                          controller: _modeloController,
                          icon: Icons.minor_crash_outlined,
                          hint: "Hilux 2024",
                        ),
                        
                        const SizedBox(height: 50),
                        _buildSubmitButton(),
                        const SizedBox(height: 40), 
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryOrange.withOpacity(0.2), width: 1),
        ),
        child: const Icon(
          Icons.shield_outlined,
          color: AppColors.primaryOrange,
          size: 65,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPremiumInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPrimary = false,
    bool readOnly = false,
    String? hint,
    String? Function(String?)? validator, 
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator, 
      onChanged: onChanged,
      readOnly: readOnly, 
      style: TextStyle(
        color: readOnly ? AppColors.primaryOrange : Colors.white, 
        fontSize: 15,
        fontWeight: readOnly ? FontWeight.bold : FontWeight.normal,
      ),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white10, fontSize: 13),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        prefixIcon: Icon(icon, color: isPrimary ? AppColors.primaryOrange : Colors.white30, size: 22),
        suffixIcon: readOnly ? const Icon(Icons.lock_outline, color: Colors.white24, size: 18) : null,
        filled: true,
        fillColor: isPrimary ? Colors.white.withOpacity(0.05) : Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: _procesando ? null : _enviarFormulario,
        child: _procesando 
          ? const SizedBox(
              height: 24, 
              width: 24, 
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
            )
          : Text(
              "ACTIVAR PROTECCIÓN",
              style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
      ),
    );
  }

  String? _validarPatente(String? value) {
    if (value == null || value.isEmpty) return "Obligatorio";
    final cleanValue = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final regexPatente = RegExp(r'^([A-Z]{4}\d{2}|[A-Z]{2}\d{4})$');
    if (!regexPatente.hasMatch(cleanValue)) {
      return "Formato de patente inválido";
    }
    return null;
  }
}