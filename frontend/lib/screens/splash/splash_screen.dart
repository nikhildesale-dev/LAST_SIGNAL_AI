import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/animations/page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../welcome/welcome_screen.dart';
import '../citizen/citizen_dashboard_screen.dart';
import '../responder/responder_dashboard_screen.dart';
import '../administrator/admin_dashboard_screen.dart';
import '../../models/app_user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _globeController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _globeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Auto navigate after initialization
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();

      Widget destination;
      if (auth.isAuthenticated) {
        switch (auth.currentRole) {
          case UserRole.citizen:
            destination = const CitizenDashboardScreen();
            break;
          case UserRole.responder:
            destination = const ResponderDashboardScreen();
            break;
          case UserRole.admin:
            destination = const AdminDashboardScreen();
            break;
        }
      } else {
        destination = const WelcomeScreen();
      }

      Navigator.pushReplacement(
        context,
        FadeSlidePageRoute(page: destination),
      );
    });
  }

  @override
  void dispose() {
    _globeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Atmospheric background glow
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.oceanGradient,
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Earth & Orbiting Communication Nodes
                  AnimatedBuilder(
                    animation: _globeController,
                    builder: (context, child) {
                      return SizedBox(
                        width: 220,
                        height: 220,
                        child: CustomPaint(
                          painter: _EarthGlobePainter(
                            rotation: _globeController.value * 2 * math.pi,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // Brand Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'LAST SIGNAL',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.icyBlue, width: 1.0),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.icyBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'OFFLINE-FIRST DISASTER MANAGEMENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: AppColors.lightMutedText,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Loading bar & status
                  const SizedBox(
                    width: 130,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.darkOceanBlue,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.icyBlue),
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Initializing Local P2P Node...',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarthGlobePainter extends CustomPainter {
  final double rotation;

  _EarthGlobePainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;

    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.teal.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, radius + 8, glowPaint);

    // Orbiting communication node ring
    final ringPaint = Paint()
      ..color = AppColors.icyBlue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2.7, height: radius * 1.1),
      ringPaint,
    );

    // Earth Base Globe (Deep Ocean Sphere)
    final globeGradient = const RadialGradient(
      center: Alignment(-0.3, -0.3),
      colors: [
        Color(0xFF1D6177),
        Color(0xFF0F394C),
        Color(0xFF082030),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = globeGradient);

    // Latitude & Longitude Geodetic lines
    final geoPaint = Paint()
      ..color = AppColors.icyBlue.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 1.5, height: radius * 2),
      -math.pi / 2,
      math.pi,
      false,
      geoPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 0.8, height: radius * 2),
      -math.pi / 2,
      math.pi,
      false,
      geoPaint,
    );

    // Rotating Continent / Landmass shapes
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    final continentPaint = Paint()
      ..color = const Color(0xFF2A839E).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = rotation + (i * (2 * math.pi / 3));
      final landX = center.dx + (radius * 0.7) * math.cos(angle);
      final landY = center.dy + (radius * 0.4) * math.sin(angle * 0.8);

      final landPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(landX, landY),
          width: radius * 0.8,
          height: radius * 0.5,
        ));
      canvas.drawPath(landPath, continentPaint);
    }
    canvas.restore();

    // Atmospheric Edge Rim
    final rimPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        colors: [
          Colors.transparent,
          AppColors.icyBlue.withOpacity(0.4),
        ],
        stops: const [0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, rimPaint);

    // Orbiting Satellite / Communication Node
    final satAngle = rotation * 1.4;
    final satX = center.dx + (radius * 1.35) * math.cos(satAngle);
    final satY = center.dy + (radius * 0.55) * math.sin(satAngle);

    // Satellite glow & dot
    canvas.drawCircle(
      Offset(satX, satY),
      5.0,
      Paint()..color = AppColors.icyBlue.withOpacity(0.4),
    );
    canvas.drawCircle(
      Offset(satX, satY),
      2.5,
      Paint()..color = AppColors.white,
    );

    // Subtle radio wave ping from satellite
    final pingPaint = Paint()
      ..color = AppColors.icyBlue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(satX, satY), 7.0, pingPaint);
  }

  @override
  bool shouldRepaint(covariant _EarthGlobePainter oldDelegate) => true;
}
