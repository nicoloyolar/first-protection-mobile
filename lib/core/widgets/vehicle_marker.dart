import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Estado visual del marcador del vehículo, compartido por el panel web y la
/// app móvil. Prioridad del color: alerta > armado > sin GPS > normal.
enum VehicleMarkerStatus { normal, armed, alert, noGps }

/// Velocidad desde la que se muestra el rumbo: mismo umbral que el firmware
/// usa para "en movimiento". Detenido, el rumbo del GPS no significa nada.
const double kHeadingMinSpeedKmh = 5;

/// El rumbo se redondea para no generar un ícono distinto por cada grado.
const int kHeadingStepDegrees = 15;

@immutable
class VehicleMarkerStyle {
  final VehicleMarkerStatus status;
  final bool gpsFix;
  final bool cutOff;

  /// Rumbo redondeado a [kHeadingStepDegrees], o null si no se muestra.
  final int? headingDegrees;

  const VehicleMarkerStyle({
    required this.status,
    required this.gpsFix,
    required this.cutOff,
    this.headingDegrees,
  });

  factory VehicleMarkerStyle.from({
    required bool alert,
    required bool armed,
    required bool cutOff,
    required bool gpsFix,
    double? headingDegrees,
    double speedKmh = 0,
  }) {
    final status = alert
        ? VehicleMarkerStatus.alert
        : armed
        ? VehicleMarkerStatus.armed
        : !gpsFix
        ? VehicleMarkerStatus.noGps
        : VehicleMarkerStatus.normal;

    int? heading;
    if (gpsFix && headingDegrees != null && speedKmh >= kHeadingMinSpeedKmh) {
      heading =
          ((headingDegrees / kHeadingStepDegrees).round() * kHeadingStepDegrees) %
          360;
    }

    return VehicleMarkerStyle(
      status: status,
      gpsFix: gpsFix,
      cutOff: cutOff,
      headingDegrees: heading,
    );
  }

  Color get color => switch (status) {
    VehicleMarkerStatus.normal => const Color(0xFF2E7D32),
    VehicleMarkerStatus.armed => const Color(0xFF1565C0),
    VehicleMarkerStatus.alert => const Color(0xFFD32F2F),
    VehicleMarkerStatus.noGps => const Color(0xFF757575),
  };

  /// Pin genérico mientras se dibuja el ícono propio (es asíncrono).
  double get fallbackHue => switch (status) {
    VehicleMarkerStatus.normal => BitmapDescriptor.hueGreen,
    VehicleMarkerStatus.armed => BitmapDescriptor.hueAzure,
    VehicleMarkerStatus.alert => BitmapDescriptor.hueRed,
    VehicleMarkerStatus.noGps => BitmapDescriptor.hueViolet,
  };

  @override
  bool operator ==(Object other) =>
      other is VehicleMarkerStyle &&
      other.status == status &&
      other.gpsFix == gpsFix &&
      other.cutOff == cutOff &&
      other.headingDegrees == headingDegrees;

  @override
  int get hashCode => Object.hash(status, gpsFix, cutOff, headingDegrees);
}

/// Genera y cachea los íconos. Avisa con [notifyListeners] cuando termina de
/// dibujar uno nuevo, para que la pantalla reconstruya sus marcadores.
class VehicleMarkerIcons extends ChangeNotifier {
  /// Tamaño lógico del ícono, con espacio alrededor para la flecha de rumbo.
  static const double logicalSize = 64;
  static const double _renderScale = 3;

  final Map<VehicleMarkerStyle, BitmapDescriptor> _cache = {};
  final Set<VehicleMarkerStyle> _pending = {};
  bool _disposed = false;

  BitmapDescriptor iconFor(VehicleMarkerStyle style) {
    final cached = _cache[style];
    if (cached != null) return cached;

    if (_pending.add(style)) {
      _render(style).then((icon) {
        _pending.remove(style);
        if (_disposed) return;
        _cache[style] = icon;
        notifyListeners();
      });
    }
    return BitmapDescriptor.defaultMarkerWithHue(style.fallbackHue);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static Future<BitmapDescriptor> _render(VehicleMarkerStyle style) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_renderScale);
    _paint(canvas, style);

    final pixels = (logicalSize * _renderScale).round();
    final image = await recorder.endRecording().toImage(pixels, pixels);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: logicalSize,
      height: logicalSize,
    );
  }

  static void _paint(Canvas canvas, VehicleMarkerStyle style) {
    const center = Offset(logicalSize / 2, logicalSize / 2);
    const radius = 17.0;
    final fill = Paint()..color = style.color;

    // Flecha de rumbo, dibujada dentro de la imagen: en web los marcadores
    // no se pueden rotar.
    final heading = style.headingDegrees;
    if (heading != null) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(heading * math.pi / 180);
      final arrow = Path()
        ..moveTo(0, -(radius + 11))
        ..lineTo(-8, -(radius - 2))
        ..lineTo(8, -(radius - 2))
        ..close();
      canvas.drawPath(arrow, fill);
      canvas.drawPath(
        arrow,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center.translate(0, 1.5),
      radius + 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawCircle(center, radius, fill);

    // Borde blanco; punteado cuando no hay fix de GPS.
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    if (style.gpsFix) {
      canvas.drawCircle(center, radius, border);
    } else {
      const dashes = 12;
      const sweep = 2 * math.pi / dashes;
      final rect = Rect.fromCircle(center: center, radius: radius);
      for (var i = 0; i < dashes; i++) {
        canvas.drawArc(rect, i * sweep, sweep * 0.55, false, border);
      }
    }

    _paintIcon(canvas, Icons.directions_car_filled, center, 20, Colors.white);

    if (style.cutOff) {
      final badge = center.translate(radius * 0.72, radius * 0.72);
      canvas.drawCircle(badge, 8, Paint()..color = const Color(0xFF212121));
      canvas.drawCircle(
        badge,
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      _paintIcon(canvas, Icons.lock, badge, 10, Colors.white);
    }
  }

  static void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }
}
