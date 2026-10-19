import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/emergency_location.dart';
import '../../models/hazard_report.dart';
import '../../providers/emergency_pack_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/routing_service.dart';
import '../../widgets/primary_button.dart';

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
  bool _isWalkingMode = false;
  String _mapFilter = 'All'; // 'All', 'Hospitals', 'Shelters', 'Hazards'

  @override
  void initState() {
    super.initState();
    final pack = context.read<EmergencyPackProvider>();
    _selectedDestination = widget.initialDestination ??
        (pack.savedLocations.isNotEmpty
            ? pack.savedLocations.first
            : const EmergencyLocation(
                id: 'LOC-FALLBACK',
                name: 'Sector 3 Central Safe Staging',
                type: LocationType.shelter,
                sampleAddress: 'Sector 3 Plaza, High Ridge',
                distanceKm: 2.4,
                latitude: 18.9380,
                longitude: 72.8290,
                capacity: 100,
                occupied: 42,
                contactPhone: '+1-800-555-0199',
                availableServices: ['Emergency Triage', 'Water Supply'],
              ));
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

  int get _calculatedEtaMinutes {
    final distance = _selectedDestination.distanceKm;
    if (_isWalkingMode) {
      // Walking speed ~ 4.2 km/h
      return (distance / 4.2 * 60).round() + 4;
    } else {
      // Emergency vehicle / convoy ~ 24 km/h with obstacle buffer
      return (distance / 24.0 * 60).round() + 5;
    }
  }

  void _showTurnByTurnModal() {
    if (_routeResult == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkOceanBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.turn_right, color: AppColors.icyBlue, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'TURN-BY-TURN GUIDANCE',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.icyBlue),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.mutedText),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Destination: ${_selectedDestination.name} (${_selectedDestination.distanceKm} km • $_calculatedEtaMinutes mins ${_isWalkingMode ? "walking" : "by vehicle"})',
                style: const TextStyle(fontSize: 12, color: AppColors.lightMutedText),
              ),
              const Divider(height: 20),
              ..._routeResult!.navigationDirectives.map((step) {
                final isWarning = step.contains('CAUTION');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isWarning ? Icons.warning_amber_rounded : Icons.navigation_outlined,
                        size: 16,
                        color: isWarning ? AppColors.warningAmber : AppColors.teal,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
                            color: isWarning ? AppColors.warningAmber : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Close Guidance',
                height: 40,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pack = context.watch<EmergencyPackProvider>();
    final reports = context.watch<ReportProvider>();
    final verifiedHazards = reports.allReports.where((r) => r.status != 'Draft').toList();

    // Apply map filtering
    final filteredDestinations = pack.savedLocations.where((loc) {
      if (_mapFilter == 'Hospitals') return loc.type == LocationType.hospital;
      if (_mapFilter == 'Shelters') return loc.type == LocationType.shelter;
      return true;
    }).toList();

    final filteredHazards = _mapFilter == 'Hospitals' || _mapFilter == 'Shelters'
        ? <HazardReport>[]
        : verifiedHazards;

    return Scaffold(
      backgroundColor: AppColors.deepOceanNavy,
      appBar: AppBar(
        title: const Text('EMERGENCY MAP & CORRIDORS'),
        actions: [
          IconButton(
            tooltip: 'Reset View',
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
                  destinations: filteredDestinations,
                  selectedDestination: _selectedDestination,
                  hazards: filteredHazards,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.darkOceanBlue.withOpacity(0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderNavy),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_pin, size: 15, color: AppColors.successGreen),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tactical Vector Map • Offline Emergency Corridors (Simulated GPS)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.lightMutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Filter Pills
          Positioned(
            top: 48,
            left: 12,
            right: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Hospitals', 'Shelters', 'Hazards'].map((filter) {
                  final isSelected = _mapFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.lightMutedText,
                        ),
                      ),
                      selectedColor: AppColors.teal,
                      backgroundColor: AppColors.darkOceanBlue.withOpacity(0.85),
                      side: BorderSide(color: isSelected ? AppColors.icyBlue : AppColors.borderNavy),
                      onSelected: (_) => setState(() => _mapFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Map Zoom & Center Control Buttons
          Positioned(
            right: 14,
            top: 48,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: () => setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(0.7, 2.8)),
                ),
                const SizedBox(height: 6),
                _buildMapControlBtn(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: () => setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(0.7, 2.8)),
                ),
                const SizedBox(height: 6),
                _buildMapControlBtn(
                  icon: Icons.my_location,
                  tooltip: 'Center on Me',
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
            bottom: 230,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkOceanBlue.withOpacity(0.88),
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
                  _buildLegendItem(Icons.block, AppColors.emergencyRed, 'Road Blocks'),
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
                  if (_isCalculatingRoute)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.deepOceanNavy,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.icyBlue),
                        minHeight: 2,
                      ),
                    ),

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

                  // Destination Name & Route Metrics
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

                  // Mode of Travel Toggle & ETA Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.deepOceanNavy,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderNavy),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isWalkingMode ? Icons.directions_walk : Icons.directions_car,
                              size: 18,
                              color: AppColors.icyBlue,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ETA: $_calculatedEtaMinutes minutes',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  _isWalkingMode ? 'Walking speed (~4 km/h)' : 'Vehicle convoy speed (~24 km/h)',
                                  style: const TextStyle(fontSize: 10, color: AppColors.lightMutedText),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Toggle Button
                        Row(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _isWalkingMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !_isWalkingMode ? AppColors.teal : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Convoy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => setState(() => _isWalkingMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isWalkingMode ? AppColors.teal : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Foot', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Hazard Advisory along route
                  if (_routeResult != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.deepOceanNavy,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderNavy),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _routeResult!.intersectingHazards.isNotEmpty
                                ? Icons.warning_amber_rounded
                                : Icons.verified_user_outlined,
                            size: 16,
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

                  // Action Buttons: Turn-by-Turn & Lock Route
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.list_alt, size: 16),
                          label: const Text('Guidance Steps', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            side: const BorderSide(color: AppColors.icyBlue),
                          ),
                          onPressed: _showTurnByTurnModal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Lock Corridor',
                          icon: Icons.navigation_outlined,
                          height: 42,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Safe emergency corridor locked to ${_selectedDestination.name}. Route cached for offline transit.',
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

  Widget _buildMapControlBtn({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkOceanBlue.withOpacity(0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderNavy),
        ),
        child: Icon(icon, size: 18, color: AppColors.icyBlue),
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
    final center = Offset(size.width / 2, size.height * 0.40) + pan;

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
