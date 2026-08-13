/// Formatea una distancia en metros para mostrarla en la UI, con el mismo
/// criterio en toda la app (app móvil y, a futuro, panel admin).
String formatDistanceMeters(double meters) {
  if (meters < 1000) {
    return "${meters.round()} m";
  }
  return "${(meters / 1000).toStringAsFixed(1)} km";
}
