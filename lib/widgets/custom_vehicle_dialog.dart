// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:first_protection/widgets/custom_alert_dialog.dart';

class CustomVehicleDialog extends StatefulWidget {
  final Function(String patente, String marca, String modelo, String anio) onPatenteConfirmed;
  final VoidCallback onCancel;

  const CustomVehicleDialog({
    super.key,
    required this.onPatenteConfirmed,
    required this.onCancel,
  });

  @override
  _CustomVehicleDialogState createState() => _CustomVehicleDialogState();
}

class _CustomVehicleDialogState extends State<CustomVehicleDialog> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _anioController = TextEditingController();

  final RegExp consonantRegExp = RegExp(r'^[B-DF-HJ-NP-TV-Zb-df-hj-np-tv-z]$');
  final RegExp numberRegExp = RegExp(r'^[0-9]$');

  bool _isChecking = false;

  Future<void> _validateAndSubmit() async {
    final inputs = _controllers.map((c) => c.text.toUpperCase()).toList();
    if (inputs.any((e) => e.isEmpty)) {
      _showError("Debes completar todos los campos de la patente.");
      return;
    }

    final firstFour = inputs.sublist(0, 4);
    final lastTwo = inputs.sublist(4, 6);

    if (!firstFour.every((e) => consonantRegExp.hasMatch(e))) {
      _showError("Solo consonantes en las primeras 4 posiciones.");
      return;
    }
    if (!lastTwo.every((e) => numberRegExp.hasMatch(e))) {
      _showError("Solo números en las últimas 2 posiciones.");
      return;
    }

    final patenteFormatted =
        "${firstFour[0]}${firstFour[1]}-${firstFour[2]}${firstFour[3]}-${lastTwo[0]}${lastTwo[1]}";

    final marca = _marcaController.text.trim();
    final modelo = _modeloController.text.trim();
    final anio = _anioController.text.trim();

    if (marca.isEmpty || modelo.isEmpty || anio.isEmpty) {
      _showError("Completa marca, modelo y año.");
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(anio)) {
      _showError("El año debe tener 4 dígitos.");
      return;
    }

    setState(() {
      _isChecking = true;
    });

    final existing = await FirebaseFirestore.instance
        .collection('vehiculos')
        .where('patente', isEqualTo: patenteFormatted)
        .get();

    setState(() {
      _isChecking = false;
    });

    if (existing.docs.isNotEmpty) {
      _showError("La patente ya existe.");
      return;
    }

    widget.onPatenteConfirmed(patenteFormatted, marca, modelo, anio);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => CustomAlert(
        message: message,
        icon: Icons.error,
        iconColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildLabeledInput(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade800,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Registrar Vehículo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextField(
                      controller: _controllers[index],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 1 && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              _buildLabeledInput("Marca", _marcaController),
              const SizedBox(height: 12),
              _buildLabeledInput("Modelo", _modeloController),
              const SizedBox(height: 12),
              _buildLabeledInput("Año", _anioController, keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _isChecking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _validateAndSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6C2C),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Registrar",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
