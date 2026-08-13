import 'package:first_protection/core/services/database_service.dart';
import 'package:first_protection/core/theme/app_colors.dart';
import 'package:first_protection/core/utils/formatters.dart';
import 'package:first_protection/core/widgets/custom_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Formulario para que el cliente vea y edite sus propios datos de
/// contacto y de emergencia. Del lado del panel admin ya existía este
/// mismo formulario (`device_inventory_screen.dart`) — acá se replica el
/// mismo esquema de datos (campos planos en `dispositivos/{idDispositivo}`,
/// no en `usuarios/{uid}`), solo con los campos que le corresponde editar
/// al cliente (no marca/modelo/patente ni campos operativos internos).
class DatosPropietarioScreen extends StatefulWidget {
  const DatosPropietarioScreen({
    super.key,
    required this.idDispositivo,
    required this.alias,
  });

  final String idDispositivo;
  final String alias;

  @override
  State<DatosPropietarioScreen> createState() =>
      _DatosPropietarioScreenState();
}

class _DatosPropietarioScreenState extends State<DatosPropietarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();

  final _nombreController = TextEditingController();
  final _rutController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _domicilioController = TextEditingController();
  final _nombreEmergenciaController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();
  final _comentarioController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await _databaseService.obtenerDatosPropietario(
      widget.idDispositivo,
    );

    _nombreController.text = datos['nombrePropietario'] ?? '';
    _rutController.text = datos['rutPropietario'] ?? '';
    _emailController.text = datos['emailPropietario'] ?? '';
    _telefonoController.text = (datos['telefonoPropietario'] ?? '')
        .replaceFirst('+569', '');
    _domicilioController.text = datos['domicilioPropietario'] ?? '';
    _nombreEmergenciaController.text = datos['nombreEmergencia'] ?? '';
    _telefonoEmergenciaController.text = datos['telefonoEmergencia'] ?? '';
    _comentarioController.text = datos['comentario'] ?? '';

    if (mounted) setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rutController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _domicilioController.dispose();
    _nombreEmergenciaController.dispose();
    _telefonoEmergenciaController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final telefonoLimpio = _telefonoController.text.trim();
    try {
      await _databaseService.actualizarDatosPropietario(
        idDispositivo: widget.idDispositivo,
        nombre: _nombreController.text.trim(),
        rut: _rutController.text.trim(),
        email: _emailController.text.trim(),
        telefono: telefonoLimpio.isEmpty ? '' : '+569$telefonoLimpio',
        domicilio: _domicilioController.text.trim(),
        nombreEmergencia: _nombreEmergenciaController.text.trim(),
        telefonoEmergencia: _telefonoEmergenciaController.text.trim(),
        comentario: _comentarioController.text.trim(),
      );

      if (!mounted) return;
      FirstProtectionNotification.show(
        context: context,
        message: "Tus datos se guardaron correctamente",
        type: NotificationType.success,
      );
    } catch (e) {
      if (!mounted) return;
      FirstProtectionNotification.show(
        context: context,
        message: "No se pudo guardar: $e",
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "MIS DATOS",
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              widget.alias.toUpperCase(),
              style: GoogleFonts.roboto(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildSectionTitle("DATOS DE CONTACTO"),

                    _buildInput(
                      label: "Nombre Completo",
                      controller: _nombreController,
                      icon: Icons.badge_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Obligatorio" : null,
                    ),
                    const SizedBox(height: 15),

                    _buildInput(
                      label: "RUT",
                      controller: _rutController,
                      icon: Icons.fingerprint,
                      formatters: [ChileanFormatters.rut],
                    ),
                    const SizedBox(height: 15),

                    _buildInput(
                      label: "Email",
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return v.contains('@') ? null : "Email inválido";
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildInput(
                      label: "Teléfono Móvil",
                      controller: _telefonoController,
                      icon: Icons.phone_android,
                      hint: "12345678",
                      prefixText: "+56 9 ",
                      keyboardType: TextInputType.phone,
                      formatters: [ChileanFormatters.telefonoCl],
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        return v.length == 8 ? null : "Deben ser 8 dígitos";
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildInput(
                      label: "Domicilio",
                      controller: _domicilioController,
                      icon: Icons.home_work_outlined,
                    ),

                    const SizedBox(height: 25),
                    _buildSectionTitle("CONTACTO DE EMERGENCIA"),

                    _buildInput(
                      label: "Nombre del Contacto",
                      controller: _nombreEmergenciaController,
                      icon: Icons.contact_phone_outlined,
                    ),
                    const SizedBox(height: 15),

                    _buildInput(
                      label: "Teléfono de Emergencia",
                      controller: _telefonoEmergenciaController,
                      icon: Icons.call_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 25),
                    _buildSectionTitle("SEÑAS PARTICULARES"),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "Detalles que ayuden a identificar tu vehículo en caso "
                        "de robo: rayones, adhesivos, un foco quemado, etc.",
                        style: GoogleFonts.roboto(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildInput(
                      label: "Comentario",
                      controller: _comentarioController,
                      icon: Icons.description_outlined,
                      hint: "Ej: tiene el foco izquierdo quemado",
                      maxLines: 3,
                    ),

                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 30),
                  ],
                ),
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

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.white54, fontSize: 15),
        hintStyle: const TextStyle(color: Colors.white10, fontSize: 13),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white30, size: 22),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
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
            color: AppColors.primaryOrange.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: _guardando ? null : _guardar,
        child: _guardando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                "GUARDAR DATOS",
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
