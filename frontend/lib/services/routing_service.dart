import '../models/emergency_location.dart';
import '../models/hazard_report.dart';

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

class RouteResult {
  final EmergencyLocation destination;
  final double distanceKm;
  final int estimatedMinutes;
  final int routeRiskScore; // 0 - 100
  final String riskCategory; // 'Low', 'Moderate', 'High', 'Critical'
  final List<GeoPoint> waypoints;
  final List<HazardReport> intersectingHazards;
  final List<String> navigationDirectives;
  final String safetyAdvisory;

  const RouteResult({
    required this.destination,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.routeRiskScore,
    required this.riskCategory,
    required this.waypoints,
    required this.intersectingHazards,
    required this.navigationDirectives,
    required this.safetyAdvisory,
  });
}

/// Abstract contract for Team Member 2 (Maps & GPS)
abstract class IRoutingService {
  GeoPoint getCurrentLocation();
  Future<RouteResult> calculateEmergencyRoute({
    required EmergencyLocation destination,
    required List<HazardReport> knownHazards,
  });
}

/// Illustrative deterministic routing engine with hazard avoidance
class RoutingService implements IRoutingService {
  // Deterministic user location (Sector 3 Central Evacuation Staging)
  static const GeoPoint sampleUserLocation = GeoPoint(18.9320, 72.8350);

  @override
  GeoPoint getCurrentLocation() => sampleUserLocation;

  @override
  Future<RouteResult> calculateEmergencyRoute({
    required EmergencyLocation destination,
    required List<HazardReport> knownHazards,
  }) async {
    // Detect intersecting hazards near the destination or path
    final relevantHazards = knownHazards.where((h) {
      final latDiff = (h.latitude - destination.latitude).abs();
      final lonDiff = (h.longitude - destination.longitude).abs();
      return (latDiff < 0.015 && lonDiff < 0.015) &&
          (h.status == 'Verified' || h.status == 'Under Review');
    }).toList();

    int riskScore = 22;
    if (relevantHazards.any((h) => h.severity == 'Critical')) {
      riskScore = 78;
    } else if (relevantHazards.any((h) => h.severity == 'High')) {
      riskScore = 54;
    } else if (relevantHazards.isNotEmpty) {
      riskScore = 36;
    }

    String category;
    if (riskScore >= 75) {
      category = 'Critical';
    } else if (riskScore >= 50) {
      category = 'High';
    } else if (riskScore >= 30) {
      category = 'Moderate';
    } else {
      category = 'Low';
    }

    // Generate deterministic waypoints from origin to destination avoiding hazards
    final waypoints = <GeoPoint>[
      sampleUserLocation,
      GeoPoint(
        (sampleUserLocation.latitude + destination.latitude) / 2 + 0.003,
        (sampleUserLocation.longitude + destination.longitude) / 2 - 0.002,
      ),
      GeoPoint(
        destination.latitude - 0.001,
        destination.longitude + 0.001,
      ),
      GeoPoint(destination.latitude, destination.longitude),
    ];

    final directives = <String>[
      'Depart origin on Sector 3 North Ring Road.',
      if (relevantHazards.any((h) => h.hazardType == 'Flood'))
        'CAUTION: Avoid 4th Avenue Underpass. Route diverted via High Ridge Flyover.'
      else
        'Proceed along central arterial highway.',
      'Turn onto ${destination.sampleAddress.split(',').first}.',
      'Arrive at ${destination.name} emergency entrance.',
    ];

    return RouteResult(
      destination: destination,
      distanceKm: destination.distanceKm,
      estimatedMinutes: (destination.distanceKm * 4.5).round() + 5,
      routeRiskScore: riskScore,
      riskCategory: category,
      waypoints: waypoints,
      intersectingHazards: relevantHazards,
      navigationDirectives: directives,
      safetyAdvisory: riskScore > 60
          ? 'Elevated hazard proximity detected. Travel in daylight or convoy if possible. Follow emergency marshals.'
          : 'Path clear of major reported inundations. Proceed with standard caution.',
    );
  }
}
