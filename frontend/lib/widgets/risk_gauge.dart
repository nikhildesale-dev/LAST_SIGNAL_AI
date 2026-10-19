import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Circular animated risk gauge for AI-driven predictive disaster estimate
class RiskGauge extends StatefulWidget {
  final int targetScore; // 0 - 100
  final String category; // 'Low', 'Moderate', 'High', 'Critical'
  final double size;
  final Duration animationDuration;

  const RiskGauge({
    super.key,
    required this.targetScore,
    required this.category,
    this.size = 170,
    this.animationDuration = const Duration(milliseconds: 1600),
  });

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.targetScore.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetScore != widget.targetScore) {
      _scoreAnimation = Tween<double>(
        begin: _scoreAnimation.value,
        end: widget.targetScore.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 75) return AppColors.emergencyRed;
    if (score >= 50) return AppColors.warningAmber;
    if (score >= 25) return const Color(0xFFD49A3D);
    return AppColors.successGreen;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final currentScore = _scoreAnimation.value;
        final color = _getScoreColor(currentScore);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  score: currentScore,
                  color: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentScore.toInt().toString(),
                        style: TextStyle(
                          fontSize: widget.size * 0.24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        '/100',
                        style: TextStyle(
                          fontSize: widget.size * 0.10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.5), width: 1),
                    ),
                    child: Text(
                      widget.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: widget.size * 0.07,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RISK ESTIMATE',
                    style: TextStyle(
                      fontSize: widget.size * 0.055,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    // Start angle: 135 degrees (3pi/4), Sweep angle: 270 degrees (3pi/2)
    const startAngle = 0.75 * math.pi;
    const totalSweep = 1.5 * math.pi;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.borderNavy.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // Active score arc
    final sweepAngle = (score / 100.0) * totalSweep;
    if (sweepAngle > 0.01) {
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Glow shadow
      final shadowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        shadowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
