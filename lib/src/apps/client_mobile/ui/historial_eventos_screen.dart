import 'package:first_protection/core/services/database_service.dart';
import 'package:first_protection/core/theme/app_colors.dart';
import 'package:first_protection/core/utils/device_event_formatter.dart';
import 'package:first_protection/core/utils/time_ago.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Historial de eventos del vehículo para el cliente final: comandos
/// enviados (humo/sirena/corte) y eventos reportados por el dispositivo
/// (botón físico, manipulación, pérdida de GPS, etc.). Reutiliza el mismo
/// stream que alimenta la pestaña "Eventos" del panel admin.
class HistorialEventosScreen extends StatelessWidget {
  const HistorialEventosScreen({
    super.key,
    required this.idDispositivo,
    required this.alias,
  });

  final String idDispositivo;
  final String alias;

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "HISTORIAL",
              style: GoogleFonts.oswald(
                color: Colors.white,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            ),
            Text(
              alias.toUpperCase(),
              style: GoogleFonts.roboto(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: databaseService.escucharEventosDispositivo(idDispositivo),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            );
          }

          final eventos = snapshot.data!;
          if (eventos.isEmpty) {
            return Center(
              child: Text(
                "Todavía no hay eventos registrados",
                style: GoogleFonts.poppins(
                  color: Colors.white24,
                  fontSize: 13,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: eventos.length,
            itemBuilder: (context, index) =>
                _EventoCard(evento: eventos[index]),
          );
        },
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.evento});

  final Map<String, dynamic> evento;

  @override
  Widget build(BuildContext context) {
    final severidad = evento['severidad']?.toString() ?? 'info';
    final color = switch (severidad) {
      'critical' => Colors.redAccent,
      'warning' => Colors.orangeAccent,
      _ => Colors.white38,
    };
    final actor = DeviceEventFormatter.actorLabel(
      evento['actorRole']?.toString(),
    );

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  DeviceEventFormatter.describe(evento),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTimeAgo(evento['timestamp'] as int?),
                style: GoogleFonts.roboto(
                  color: Colors.white24,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (actor.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              actor,
              style: GoogleFonts.roboto(color: Colors.white24, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
