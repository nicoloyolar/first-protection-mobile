import 'package:first_protection/core/widgets/vehicle_marker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

VehicleMarkerStyle style({
  bool alert = false,
  bool armed = false,
  bool cutOff = false,
  bool gpsFix = true,
  double? heading,
  double speed = 0,
}) => VehicleMarkerStyle.from(
  alert: alert,
  armed: armed,
  cutOff: cutOff,
  gpsFix: gpsFix,
  headingDegrees: heading,
  speedKmh: speed,
);

void main() {
  group('VehicleMarkerStyle', () {
    test('prioridad del color: alerta > armado > sin GPS > normal', () {
      expect(style().status, VehicleMarkerStatus.normal);
      expect(style(gpsFix: false).status, VehicleMarkerStatus.noGps);
      expect(style(armed: true, gpsFix: false).status, VehicleMarkerStatus.armed);
      expect(
        style(alert: true, armed: true, gpsFix: false).status,
        VehicleMarkerStatus.alert,
      );
    });

    test('sin fix se mantiene la marca aunque el color sea de otro estado', () {
      final armadoSinGps = style(armed: true, gpsFix: false);
      expect(armadoSinGps.status, VehicleMarkerStatus.armed);
      expect(armadoSinGps.gpsFix, isFalse);
    });

    test('el rumbo solo se muestra con fix y en movimiento', () {
      expect(style(heading: 90, speed: 1).headingDegrees, isNull);
      expect(style(heading: 90, speed: 40, gpsFix: false).headingDegrees, isNull);
      expect(style(speed: 40).headingDegrees, isNull);
      expect(style(heading: 90, speed: kHeadingMinSpeedKmh).headingDegrees, 90);
    });

    test('el rumbo se redondea a pasos de 15 grados y 360 vuelve a 0', () {
      expect(style(heading: 97, speed: 40).headingDegrees, 90);
      expect(style(heading: 98, speed: 40).headingDegrees, 105);
      expect(style(heading: 355, speed: 40).headingDegrees, 0);
    });

    test('estilos iguales son iguales (para reutilizar el icono en cache)', () {
      expect(style(heading: 91, speed: 30), style(heading: 89, speed: 60));
      expect(
        style(heading: 91, speed: 30).hashCode,
        style(heading: 89, speed: 60).hashCode,
      );
      expect(style(cutOff: true), isNot(style()));
    });
  });

  testWidgets('VehicleMarkerIcons dibuja el icono y avisa al terminar', (
    tester,
  ) async {
    final icons = VehicleMarkerIcons();
    var notified = 0;
    icons.addListener(() => notified++);
    final s = style(armed: true, cutOff: true, heading: 45, speed: 30);

    // Mientras dibuja devuelve el pin generico; luego queda en cache.
    final first = icons.iconFor(s);
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && notified == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });

    expect(notified, 1);
    final cached = icons.iconFor(s);
    expect(cached, isA<BytesMapBitmap>());
    expect(identical(icons.iconFor(s), cached), isTrue);
    expect(identical(first, cached), isFalse);
    icons.dispose();
  });
}
