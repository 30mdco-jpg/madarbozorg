import 'dart:math' as math;

import 'package:flutter/material.dart';

/// موج‌های متحرک پایین سربرگ؛ سه لایه با سرعت و شفافیت متفاوت که افقی
/// می‌لغزند و ارتفاعشان آرام کم و زیاد می‌شود.
class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key, required this.waveColor});

  /// رنگ موج‌ها؛ باید با رنگ پس‌زمینهٔ صفحه یکی باشد تا سربرگ در آن محو شود.
  final Color waveColor;

  @override
  State<WaveBackground> createState() =&gt; \_WaveBackgroundState();
}

class \_WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController \_controller;

  @override
  void initState() {
    super.initState();
    \_controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    \_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: \_WavePainter(\_controller, widget.waveColor),
      ),
    );
  }
}

class \_Layer {
  const \_Layer(this.base, this.amp, this.periodSec, this.alpha);
  final double base; // ارتفاع میانگین موج، نسبت به ارتفاع کل
  final double amp; // دامنه
  final double periodSec; // زمان یک دور کامل
  final double alpha;
}

class \_WavePainter extends CustomPainter {
  \_WavePainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  // از پشت به جلو: پایینی کدر و کم‌ارتفاع، بالایی نیمه‌شفاف و بلندتر.
  static const \_layers = \[
    \_Layer(0.72, 0.12, 15, 1.0),
    \_Layer(0.55, 0.14, 10, 0.75),
    \_Layer(0.38, 0.16, 6, 0.5),
  \];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final seconds = animation.value \* 30;
    for (final layer in \_layers) {
      final phase = (seconds / layer.periodSec) % 1.0;
      // ارتفاع موج: ۱ -&gt; ۰٫۵۵ -&gt; ۱ در هر دور.
      final scale = 1 - 0.45 \* math.sin(math.pi \* phase);
      final path = Path()..moveTo(0, h);
      for (double x = 0; x &lt;= w; x += 4) {
        final y = h \* layer.base +
            h \* layer.amp \* scale \* math.sin(2 \* math.pi \* (x / w + phase));
        path.lineTo(x, y);
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = color.withAlpha((layer.alpha \* 255).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant \_WavePainter oldDelegate) =&gt;
      oldDelegate.color != color;
}