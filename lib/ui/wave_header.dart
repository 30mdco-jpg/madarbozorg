import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated waves at the bottom of the header.
/// Three layers slide sideways at different speeds and breathe in height.
class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key, required this.waveColor});

  /// Must match the page background so the header fades into the page.
  final Color waveColor;

  @override
  State<WaveBackground> createState() {
    return _WaveBackgroundState();
  }
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WavePainter(_controller, widget.waveColor),
      ),
    );
  }
}

class _Layer {
  const _Layer(this.base, this.amp, this.periodSec, this.alpha);
  final double base;
  final double amp;
  final double periodSec;
  final double alpha;
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  // Back to front: bottom one is opaque and low, top one is see-through and taller.
  static const List<_Layer> layers = [
    _Layer(0.72, 0.12, 15, 1.0),
    _Layer(0.55, 0.14, 10, 0.75),
    _Layer(0.38, 0.16, 6, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double seconds = animation.value * 30;
    const int steps = 90;
    for (final layer in layers) {
      final double phase = (seconds / layer.periodSec) % 1.0;
      final double scale = 1 - 0.45 * math.sin(math.pi * phase);
      final Path path = Path();
      path.moveTo(0, h);
      for (int i = 0; i <= steps; i++) {
        final double x = w * i / steps;
        final double y = h * layer.base +
            h *
                layer.amp *
                scale *
                math.sin(2 * math.pi * (i / steps + phase));
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.close();
      final Paint paint = Paint();
      paint.color = color.withAlpha((layer.alpha * 255).round());
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
