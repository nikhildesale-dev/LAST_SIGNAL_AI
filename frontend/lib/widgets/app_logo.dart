import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Animated radar and signal logo for LAST SIGNAL AI
class AppLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 54,
    this.animate = true,
    this.showText = false,
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoWidget = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LogoPainter(
              rotation: _controller.value * 2 * math.pi,
              pulse: (math.sin(_controller.value * 2 * math.pi) + 1) / 2,
            ),
          );
        },
      ),
    );

    if (!widget.showText) return logoWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'LAST SIGNAL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.icyBlue, width: 0.8),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.icyBlue,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'EMERGENCY INTELLIGENCE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
                color: AppColors.lightMutedText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double rotation;
  final double pulse;

  _LogoPainter({required this.rotation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer subtle ring
    final outerRingPaint = Paint()
      ..color = AppColors.teal.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 2, outerRingPaint);

    // Middle pulse ring
    final pulseRingPaint = Paint()
      ..color = AppColors.icyBlue.withOpacity(0.15 + (pulse * 0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, (radius - 8) * (0.85 + (pulse * 0.15)), pulseRingPaint);

    // Rotating radar sweep line
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.icyBlue.withOpacity(0.0),
          AppColors.icyBlue.withOpacity(0.5),
        ],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: center, radius: radius - 4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 6, sweepPaint);

    // Orbiting node dot
    final nodeAngle = rotation;
    final nodeX = center.dx + (radius - 6) * math.cos(nodeAngle);
    final nodeY = center.dy + (radius - 6) * math.sin(nodeAngle);
    final nodePaint = Paint()..color = AppColors.icyBlue;
    canvas.drawCircle(Offset(nodeX, nodeY), 3.0, nodePaint);

    // Center Core Signal
    final coreGradient = const RadialGradient(
      colors: [AppColors.icyBlue, AppColors.teal],
    ).createShader(Rect.fromCircle(center: center, radius: radius * 0.4));

    final corePaint = Paint()
      ..shader = coreGradient
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.38, corePaint);

    // Center Icon / Tower symbol
    final iconPaint = Paint()
      ..color = AppColors.deepOceanNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Signal arcs
    path.moveTo(center.dx - 5, center.dy + 4);
    path.lineTo(center.dx, center.dy - 6);
    path.lineTo(center.dx + 5, center.dy + 4);
    canvas.drawPath(path, iconPaint);

    canvas.drawCircle(Offset(center.dx, center.dy - 6), 1.5,
        Paint()..color = AppColors.deepOceanNavy);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.pulse != pulse;
  }
}
