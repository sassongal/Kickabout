import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A premium widget that renders a Gold Prism effect using a fragment shader.
class PremiumPrismShader extends StatefulWidget {
  final double alpha;

  const PremiumPrismShader({
    super.key,
    this.alpha = 0.8,
  });

  @override
  State<PremiumPrismShader> createState() => _PremiumPrismShaderState();
}

class _PremiumPrismShaderState extends State<PremiumPrismShader>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  final Stopwatch _stopwatch = Stopwatch();
  late final Ticker _ticker;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      if (mounted && _isVisible) setState(() {});
    });
    _stopwatch.start();
    _ticker.start();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.1; // At least 10% visible

    if (!wasVisible && _isVisible) {
      // Widget became visible - resume animation
      _stopwatch.start();
      _ticker.start();
    } else if (wasVisible && !_isVisible) {
      // Widget became invisible - pause animation
      _stopwatch.stop();
      _ticker.stop();
    }
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('assets/shaders/prism.frag');
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (e) {
      debugPrint('Error loading prism shader: $e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null) return const SizedBox.shrink();

    return VisibilityDetector(
      key: Key('prism_shader_${widget.key ?? hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: CustomPaint(
        painter: _PrismPainter(
          program: _program!,
          time: _stopwatch.elapsedMilliseconds / 1000.0,
          alpha: widget.alpha,
        ),
      ),
    );
  }
}

class _PrismPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double alpha;

  _PrismPainter({
    required this.program,
    required this.time,
    required this.alpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // uResolution
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // uTime
    shader.setFloat(2, time);

    // uAlpha
    shader.setFloat(3, alpha);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _PrismPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.alpha != alpha;
}
