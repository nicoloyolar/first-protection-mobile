import 'package:flutter/services.dart';

class ChileanFormatters {
  static TextInputFormatter patente = TextInputFormatter.withFunction((oldValue, newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    
    if (text.length > 6) text = text.substring(0, 6);

    String newText = "";
    for (int i = 0; i < text.length; i++) {
      if (i == 4) newText += "-";
      newText += text[i];
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  });

  static TextInputFormatter rut = TextInputFormatter.withFunction((oldValue, newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    if (text.length > 9) text = text.substring(0, 9);
    
    if (text.isEmpty) return newValue.copyWith(text: '');

    String formatted = "";
    if (text.length > 1) {
      String dv = text.substring(text.length - 1);
      String nums = text.substring(0, text.length - 1);
      formatted = "$nums-$dv";
    } else {
      formatted = text;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  });

  static String formatPatenteVisual(String? patente) {
    if (patente == null || patente.isEmpty) return "S/P";
    
    String clean = patente.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    
    if (clean.length == 6) {
      return "${clean.substring(0, 4)}-${clean.substring(4)}";
    }
    return clean; 
  }

  static TextInputFormatter telefonoCl = TextInputFormatter.withFunction((oldValue, newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) text = text.substring(0, 8);
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  });
}