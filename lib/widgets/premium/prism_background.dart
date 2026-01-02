import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kattrick/theme/premium_theme.dart';

class PrismBackground extends StatefulWidget {
  /// Opacity of the prism effect itself (controlled by shader uniform).
  /// Note: This is separate from the Widget's opacity.
  final double opacity;

  const PrismBackground({super.key, this.opacity = 1.0});

  @override
  State<PrismBackground> createState() => _PrismBackgroundState();
}

class _PrismBackgroundState extends State<PrismBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    _initShader();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    });
    _ticker.start();
  }

  Future<void> _initShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('assets/shaders/prism.frag');
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (e) {
      debugPrint('Shader compile error: $e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If shader not loaded, return fallback gradient so something is visible
    if (_program == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900.withValues(alpha: 0.3),
              Colors.purple.shade900.withValues(alpha: 0.3),
              Colors.teal.shade900.withValues(alpha: 0.2),
            ],
          ),
        ),
      );
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: _PrismPainter(
          shader: _program!.fragmentShader(),
          time: _time,
          opacity: widget.opacity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PrismPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final double opacity;

  _PrismPainter(
      {required this.shader, required this.time, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Update uniforms matches the shader order:
    // uniform vec2 uResolution; (0, 1)
    // uniform float uTime;      (2)
    // uniform float uAlpha;     (3)

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, opacity);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _PrismPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.opacity != opacity;
  }
}
