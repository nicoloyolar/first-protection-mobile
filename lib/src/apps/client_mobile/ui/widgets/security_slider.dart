import 'package:first_protection/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Control de "deslizar para confirmar" para acciones críticas (hoy: corte
/// de corriente). Antes se implementaba sobre un `Slider` de Material, que
/// por defecto mueve el valor al punto exacto donde se toca el track —
/// un solo tap cerca del borde derecho alcanzaba a superar el umbral y
/// disparaba la acción sin que el usuario arrastrara nada. Acá el gesto
/// solo responde si el arrastre empieza sobre el thumb, y se agrega una
/// barra de progreso para que el usuario vea qué tan cerca está del umbral.
class SecuritySlider extends StatefulWidget {
  final String text;
  final bool isActive;
  final Future<void> Function() onFinished;

  const SecuritySlider({
    super.key,
    required this.text,
    required this.isActive,
    required this.onFinished,
  });

  @override
  State<SecuritySlider> createState() => _SecuritySliderState();
}

class _SecuritySliderState extends State<SecuritySlider>
    with SingleTickerProviderStateMixin {
  static const double _thumbSize = 55.0;
  static const double _padding = 5.0;
  static const double _threshold = 0.9;

  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  double _progress = 0.0;
  bool _isDragging = false;
  bool _isLoading = false;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (_snapAnimation != null) {
          setState(() => _progress = _snapAnimation!.value);
        }
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _animarRegresoA(double destino) {
    _snapAnimation = Tween<double>(begin: _progress, end: destino).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
  }

  void _onPanStart(DragStartDetails details, double travel) {
    if (_isLoading) return;
    _snapController.stop();
    _hapticFired = false;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details, double travel) {
    if (_isLoading || !_isDragging || travel <= 0) return;
    final nuevoProgreso = (_progress + details.delta.dx / travel).clamp(
      0.0,
      1.0,
    );
    if (nuevoProgreso > 0.1 && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.selectionClick();
    }
    setState(() => _progress = nuevoProgreso);
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_isLoading) return;
    setState(() => _isDragging = false);

    if (_progress >= _threshold) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = true;
        _progress = 1.0;
      });
      await widget.onFinished();
      if (!mounted) return;
      setState(() => _isLoading = false);
      _animarRegresoA(0.0);
    } else {
      _animarRegresoA(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isActive ? Colors.green : AppColors.primaryOrange;

    return Container(
      height: 65,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = constraints.maxWidth - _thumbSize - (_padding * 2);
          final position = _progress * travel;
          final fillWidth = (_padding + position + _thumbSize).clamp(
            0.0,
            constraints.maxWidth,
          );

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Barra de progreso: reemplaza al track invisible del Slider
              // anterior, que no daba ninguna señal de cuánto faltaba para
              // el umbral.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: fillWidth,
                child: Container(color: activeColor.withValues(alpha: 0.12)),
              ),
              Center(
                child: Opacity(
                  opacity: (1.0 - (_progress * 1.5)).clamp(0.0, 1.0),
                  child: Text(
                    _isLoading ? "PROCESANDO..." : widget.text,
                    style: GoogleFonts.oswald(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _padding + position,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) => _onPanStart(d, travel),
                  onHorizontalDragUpdate: (d) => _onPanUpdate(d, travel),
                  onHorizontalDragEnd: _onPanEnd,
                  child: Container(
                    height: _thumbSize,
                    width: _thumbSize,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            widget.isActive
                                ? Icons.lock_open_rounded
                                : Icons.power_settings_new_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
