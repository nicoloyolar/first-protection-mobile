/// Formatea una marca de tiempo (epoch millis) como texto relativo en
/// español ("hace 2 min", "hace 3 h"). Compartido entre el panel admin y
/// la app móvil para no duplicar la misma lógica en cada pantalla.
String formatTimeAgo(int? millis) {
  if (millis == null || millis == 0) return "sin datos";

  final diff = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(millis),
  );

  if (diff.isNegative) return "hace instantes";
  if (diff.inSeconds < 60) return "hace ${diff.inSeconds} s";
  if (diff.inMinutes < 60) return "hace ${diff.inMinutes} min";
  if (diff.inHours < 24) return "hace ${diff.inHours} h";
  return "hace ${diff.inDays} d";
}
