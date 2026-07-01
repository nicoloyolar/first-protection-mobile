import 'package:first_protection/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _SecuritySliderState extends State<SecuritySlider> {
  double _value = 0.0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha:0.05)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const thumbSize = 55.0;
          const padding = 5.0;
          final position =
              _value * (constraints.maxWidth - thumbSize - (padding * 2));

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Opacity(
                  opacity: (1.0 - (_value * 1.5)).clamp(0.0, 1.0),
                  child: Text(
                    _isLoading ? "PROCESANDO..." : widget.text,
                    style: GoogleFonts.oswald(
                      color: Colors.white.withValues(alpha:0.3),
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 65,
                  thumbShape: SliderComponentShape.noThumb,
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                ),
                child: Slider(
                  value: _value,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value > 0.1 && _value <= 0.1) {
                            HapticFeedback.selectionClick();
                          }
                          setState(() => _value = value);
                        },
                  onChangeEnd: (value) async {
                    if (value > 0.9) {
                      HapticFeedback.heavyImpact();
                      setState(() => _isLoading = true);
                      await widget.onFinished();
                      if (mounted) setState(() => _isLoading = false);
                    }
                    setState(() => _value = 0.0);
                  },
                ),
              ),
              Positioned(
                left: padding + position,
                child: Container(
                  height: thumbSize,
                  width: thumbSize,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? Colors.green
                        : AppColors.primaryOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.isActive
                                    ? Colors.green
                                    : AppColors.primaryOrange)
                                .withValues(alpha:0.3),
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
            ],
          );
        },
      ),
    );
  }
}
