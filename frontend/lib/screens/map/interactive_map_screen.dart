import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/emergency_location.dart';
import '../../models/hazard_report.dart';
import '../../providers/emergency_pack_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/routing_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';

class InteractiveMapScreen extends StatefulWidget {
  final EmergencyLocation? initialDestination;

  const InteractiveMapScreen({super.key, this.initialDestination});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  final RoutingService _routingService = RoutingService();
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  late EmergencyLocation _selectedDestination;
  RouteResult? _routeResult;
  bool _isCalculatingRoute = false;

  @override
  void initState() {
    super.initState();
    final pack = context.read<EmergencyPackProvider>();
    _selectedDestination = widget.initialDestination ??
        (pack.savedLocations.isNotEmpty
            ? pack.savedLocations.first
            : RoutingService.sampleUserLocation as dynamic);
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    setState(() => _isCalculatingRoute = true);
    final reports = context.read<ReportProvider>();
    final result = await _routingService.calculateEmergencyRoute(
      destination: _selectedDestination,
      knownHazards: reports.allReports,
    );
    if (mounted) {
      setState(() {
        _routeResult = result;
        _isCalculatingRoute = false;
      });
    }
  }

  void _selectDestination(EmergencyLocation dest) {
    setState(() {
      _selectedDestination = dest;
    });
    _calculateRoute();
  }

  @override
  Widget build(BuildContext context) {
    final pack = context.watch<EmergencyPackProvider>();
    final reports = context.watch<ReportProvider>();
    final verifiedHazards = reports.allReports.where((r) => r.status != 'Draft').toList();

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('EMERGENCY MAP & CORRIDORS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.icyBlue),
            onPressed: () {
              setState(() {
                _zoomLevel = 1.0;
                _panOffset = Offset.zero;
              });
              _calculateRoute();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Interactive Custom Painter Map Canvas with Gesture Support
          GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                _zoomLevel = (_zoomLevel * details.scale).clamp(0.7, 2.8);
                _panOffset += details.focalPointDelta;
              });
            },
            child: ClipRect(
              child: CustomPaint(
                size: Size.infinite,
                painter: _MapCanvasPainter(
                  userLocation: RoutingService.sampleUserLocation,
                  destinations: pack.savedLocations,
                  selectedDestination: _selectedDestination,
                  hazards: verifiedHazards,
                  routeResult: _routeResult,
                  zoom: _zoomLevel,
                  pan: _panOffset,
                ),
              ),
            ),
          ),

          // Top Floating Disclaimer Banner
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkOceanBlue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderNavy),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_pin, size: 14, color: AppColors.successGreen),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Illustrative Vector Map • Cached for Offline Emergency Routing (Demo)',
                      style: TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Zoom & Center Control Buttons
          Positioned(
            right: 16,
            top: 60,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.add,
                  onTap: () => setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(0.7, 2.8)),
                ),
                const SizedBox(height: 6),
                _buildMapControlBtn(
                  icon: Icons.remove,
                  onTap: () => setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(0.7, 2.8)),
                ),
                const SizedBox(height: 6),
                _buildMapControlBtn(
                  icon: Icons.my_location,
                  onTap: () => setState(() {
                    _zoomLevel = 1.0;
                    _panOffset = Offset.zero;
                  }),
                ),
              ],
            ),
          ),

          // Map Legend Card
          Positioned(
            left: 14,
            top: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkOceanBlue.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderNavy),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(Icons.navigation, AppColors.icyBlue, 'My Position'),
                  const SizedBox(height: 4),
                  _buildLegendItem(Icons.local_hospital, AppColors.emergencyRed, 'Hospitals'),
                  const SizedBox(height: 4),
                  _buildLegendItem(Icons.night_shelter, AppColors.teal, 'Shelters'),
                  const SizedBox(height: 4),
                  _buildLegendItem(Icons.water_drop, AppColors.warningAmber, 'Floods'),
                  const SizedBox(height: 4),
                  _buildLegendItem(Icons.block, AppColors.emergencyRed, 'Blocked Roads'),
                ],
              ),
            ),
          ),

          // Bottom Route Assessment & Destination Details Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkOceanBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: const Border(top: BorderSide(color: AppColors.borderNavy, width: 1.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination Selection Chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pack.savedLocations.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final loc = pack.savedLocations[index];
                        final isSelected = loc.id == _selectedDestination.id;
                        return ChoiceChip(
                          selected: isSelected,
                          onSelected: (_) => _selectDestination(loc),
                          label: Text(
                            loc.name.split(' ').take(2).join(' '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.white : AppColors.lightMutedText,
                            ),
                          ),
                          selectedColor: AppColors.teal,
                          backgroundColor: AppColors.deepOceanNavy,
                          side: BorderSide(color: isSelected ? AppColors.icyBlue : AppColors.borderNavy),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Route Risk Metric & Destination Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDestination.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_selectedDestination.sampleAddress} • ${_selectedDestination.distanceKm} km',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (_routeResult != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (_routeResult!.routeRiskScore > 50
                                    ? AppColors.emergencyRed
                                    : AppColors.successGreen)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _routeResult!.routeRiskScore > 50
                                  ? AppColors.emergencyRed
                                  : AppColors.successGreen,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_routeResult!.routeRiskScore}/100',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _routeResult!.routeRiskScore > 50
                                      ? AppColors.emergencyRed
                                      : AppColors.successGreen,
                                ),
                              ),
                              Text(
                                'ROUTE RISK',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: _routeResult!.routeRiskScore > 50
                                      ? AppColors.emergencyRed
                                      : AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Hazard Advisory along route
                  if (_routeResult != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.deepOceanNavy,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderNavy),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _routeResult!.intersectingHazards.isNotEmpty
                                ? Icons.warning_amber_rounded
                                : Icons.verified_user_outlined,
                            size: 18,
                            color: _routeResult!.intersectingHazards.isNotEmpty
                                ? AppColors.warningAmber
                                : AppColors.successGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _routeResult!.safetyAdvisory,
                              style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Navigation Action Button
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Simulate Navigation Corridors',
                          icon: Icons.directions_outlined,
                          height: 44,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Route guidance locked to ${_selectedDestination.name}. Intersecting hazards avoided.',
                                ),
                                backgroundColor: AppColors.teal,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkOceanBlue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderNavy),
        ),
        child: Icon(icon, size: 20, color: AppColors.icyBlue),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final GeoPoint userLocation;
  final List<EmergencyLocation> destinations;
  final EmergencyLocation selectedDestination;
  final List<HazardReport> hazards;
  final RouteResult? routeResult;
  final double zoom;
  final Offset pan;

  _MapCanvasPainter({
    required this.userLocation,
    required this.destinations,
    required this.selectedDestination,
    required this.hazards,
    required this.routeResult,
    required this.zoom,
    required this.pan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42) + pan;

    // Background water and land grid
    final waterPaint = Paint()..color = const Color(0xFF091F2F);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), waterPaint);

    // Coastline & Arterial Grid lines
    final roadPaint = Paint()
      ..color = const Color(0xFF14455E)
      ..strokeWidth = 2.0 * zoom
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFF0E3245)
      ..strokeWidth = 1.0 * zoom
      ..style = PaintingStyle.stroke;

    // Draw arterial network lines
    for (int i = -4; i <= 4; i++) {
      final y = center.dy + (i * 70 * zoom);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);

      final x = center.dx + (i * 70 * zoom);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }

    // Main Coastline Curved Highway
    final highwayPath = Path()
      ..moveTo(center.dx - 180 * zoom, center.dy + 220 * zoom)
      ..quadraticBezierTo(
        center.dx - 40 * zoom,
        center.dy + 80 * zoom,
        center.dx + 160 * zoom,
        center.dy - 180 * zoom,
      );
    canvas.drawPath(highwayPath, roadPaint);

    // Coordinate conversion helper (relative to user location)
    Offset toCanvas(double lat, double lon) {
      final dx = (lon - userLocation.longitude) * 12000 * zoom;
      final dy = -(lat - userLocation.latitude) * 12000 * zoom;
      return center + Offset(dx, dy);
    }

    // Draw Safe Route Overlay if destination is selected
    if (routeResult != null && routeResult!.waypoints.isNotEmpty) {
      final routePath = Path();
      for (int i = 0; i < routeResult!.waypoints.length; i++) {
        final pt = routeResult!.waypoints[i];
        final offset = toCanvas(pt.latitude, pt.longitude);
        if (i == 0) {
          routePath.moveTo(offset.dx, offset.dy);
        } else {
          routePath.lineTo(offset.dx, offset.dy);
        }
      }

      // Route Glow
      final glowPaint = Paint()
        ..color = (routeResult!.routeRiskScore > 50 ? AppColors.emergencyRed : AppColors.icyBlue)
            .withOpacity(0.35)
        ..strokeWidth = 10.0 * zoom
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(routePath, glowPaint);

      // Route Line
      final linePaint = Paint()
        ..color = routeResult!.routeRiskScore > 50 ? AppColors.emergencyRed : AppColors.icyBlue
        ..strokeWidth = 3.5 * zoom
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(routePath, linePaint);
    }

    // Draw Hazard Markers (Floods, Blocked Roads)
    for (final h in hazards) {
      final offset = toCanvas(h.latitude, h.longitude);
      final isFlood = h.hazardType == 'Flood';
      final hazardColor = isFlood ? AppColors.warningAmber : AppColors.emergencyRed;

      // Hazard exclusion radius circle
      final zonePaint = Paint()
        ..color = hazardColor.withOpacity(0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 22 * zoom, zonePaint);

      final markerPaint = Paint()
        ..color = hazardColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 6 * zoom, markerPaint);

      // Warning ring
      final ringPaint = Paint()
        ..color = hazardColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(offset, 12 * zoom, ringPaint);
    }

    // Draw Destination Markers (Hospitals & Shelters)
    for (final loc in destinations) {
      final offset = toCanvas(loc.latitude, loc.longitude);
      final isSelected = loc.id == selectedDestination.id;
      final isHospital = loc.type == LocationType.hospital;
      final markerColor = isHospital ? AppColors.emergencyRed : AppColors.teal;

      if (isSelected) {
        // Selection pulsing halo
        final haloPaint = Paint()
          ..color = AppColors.icyBlue.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(offset, 18 * zoom, haloPaint);
      }

      final locPaint = Paint()..color = markerColor;
      canvas.drawCircle(offset, (isSelected ? 9.0 : 7.0) * zoom, locPaint);

      final iconBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(offset, (isSelected ? 9.0 : 7.0) * zoom, iconBorder);
    }

    // Draw User Location (Pulsing Radar Pin)
    final userPos = toCanvas(userLocation.latitude, userLocation.longitude);

    final userPulsePaint = Paint()
      ..color = AppColors.icyBlue.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userPos, 16 * zoom, userPulsePaint);

    final userPinPaint = Paint()..color = AppColors.icyBlue;
    canvas.drawCircle(userPos, 6 * zoom, userPinPaint);

    final userWhiteDot = Paint()..color = Colors.white;
    canvas.drawCircle(userPos, 2.5 * zoom, userWhiteDot);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.zoom != zoom ||
        oldDelegate.pan != pan ||
        oldDelegate.selectedDestination != selectedDestination ||
        oldDelegate.routeResult != routeResult;
  }
}
