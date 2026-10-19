import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Atmospheric animated particle background for LAST SIGNAL AI
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final bool showGrid;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.particleCount = 20,
    this.showGrid = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speedX: (_random.nextDouble() - 0.5) * 0.08,
        speedY: (_random.nextDouble() - 0.5) * 0.08,
        radius: 1.5 + _random.nextDouble() * 2.5,
        opacity: 0.15 + _random.nextDouble() * 0.35,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base deep ocean gradient
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.oceanGradient,
          ),
        ),

        // Animated particles and mesh
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ParticlePainter(
                particles: _particles,
                time: _controller.value,
                showGrid: widget.showGrid,
              ),
            );
          },
        ),

        // Child content on top
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double speedX;
  double speedY;
  double radius;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.radius,
    required this.opacity,
  });

  void update() {
    x += speedX * 0.02;
    y += speedY * 0.02;
    if (x < 0) x = 1.0;
    if (x > 1.0) x = 0.0;
    if (y < 0) y = 1.0;
    if (y > 1.0) y = 0.0;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final bool showGrid;

  _ParticlePainter({
    required this.particles,
    required this.time,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle coordinate grid lines
    if (showGrid) {
      final gridPaint = Paint()
        ..color = AppColors.borderNavy.withOpacity(0.18)
        ..strokeWidth = 0.8;

      const spacing = 50.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Top atmosphere radial glow
    final glowCenter = Offset(size.width * 0.5, size.height * 0.15);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.teal.withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: size.width * 0.8));

    canvas.drawCircle(glowCenter, size.width * 0.8, glowPaint);

    // Draw particles and interconnecting lines
    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      p1.update();

      final p1Offset = Offset(p1.x * size.width, p1.y * size.height);

      // Connect nearby particles with subtle lines
      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final p2Offset = Offset(p2.x * size.width, p2.y * size.height);
        final distance = (p1Offset - p2Offset).distance;

        if (distance < 110) {
          final lineOpacity = (1.0 - (distance / 110)) * 0.22;
          final linePaint = Paint()
            ..color = AppColors.icyBlue.withOpacity(lineOpacity)
            ..strokeWidth = 0.8;
          canvas.drawLine(p1Offset, p2Offset, linePaint);
        }
      }

      // Draw particle dot
      final dotPaint = Paint()
        ..color = AppColors.icyBlue.withOpacity(p1.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p1Offset, p1.radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
