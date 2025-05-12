// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CustomAlert extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancelButton; 

  const CustomAlert({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.iconColor = const Color(0xFFFF6C2C),
    this.onConfirm,
    this.onCancel,
    this.showCancelButton = false, 
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.15),
              ),
              padding: EdgeInsets.all(16),
              child: Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Atención",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                if (showCancelButton) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancelar",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm ?? () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      showCancelButton ? "Salir" : "Cerrar", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
