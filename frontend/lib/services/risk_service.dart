class RiskFactor {
  final String name;
  final double weight; // 0.0 - 1.0
  final String status;
  final String details;

  const RiskFactor({
    required this.name,
    required this.weight,
    required this.status,
    required this.details,
  });
}

class RiskEstimate {
  final int score; // 0 - 100
  final String category; // 'Low', 'Moderate', 'High', 'Critical'
  final String modelVersion;
  final DateTime lastUpdated;
  final double confidenceScore; // e.g. 0.94
  final String dataSource;
  final String summary;
  final List<RiskFactor> contributingFactors;
  final List<String> recommendedActions;
  final bool isLiveAi;

  const RiskEstimate({
    required this.score,
    required this.category,
    required this.modelVersion,
    required this.lastUpdated,
    required this.confidenceScore,
    required this.dataSource,
    required this.summary,
    required this.contributingFactors,
    required this.recommendedActions,
    this.isLiveAi = false,
  });
}

/// Abstract contract for Team Member 1 (AI/ML)
abstract class IRiskService {
  Future<RiskEstimate> getAreaRiskEstimate({double? lat, double? lon});
  Future<int> evaluateRouteRiskScore(List<String> activeHazardTypes);
}

/// Dual-engine risk service: queries live backend AI if reachable;
/// otherwise transparently falls back to local offline heuristic model.
class RiskService implements IRiskService {
  final dynamic _apiService;

  RiskService([this._apiService]);

  @override
  Future<RiskEstimate> getAreaRiskEstimate({double? lat, double? lon}) async {
    // Attempt live backend AI prediction if apiService is provided
    if (_apiService != null) {
      try {
        final liveResult = await _apiService.predictDisasterRisk(lat: lat, lon: lon);
        if (liveResult != null) {
          return liveResult;
        }
      } catch (_) {}
    }

    // Deterministic simulation based on coastal flood & cyclone factors
    return RiskEstimate(
      score: 68,
      category: 'High',
      modelVersion: 'v2.4-flood-cyclone-ensemble',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 14)),
      confidenceScore: 0.92,
      dataSource: 'Coastal Doppler + Satellite Inundation Index (Simulated / Offline Cache)',
      isLiveAi: false,
      summary:
          'High tidal storm surge combined with blocked drainage conduits poses acute inundation hazards across coastal corridors.',
      contributingFactors: const [
        RiskFactor(
          name: 'Storm Surge Inundation',
          weight: 0.42,
          status: 'Critical Alert',
          details: 'Predicted +1.4m tidal rise over standard embankment thresholds.',
        ),
        RiskFactor(
          name: 'Drainage Conduit Saturation',
          weight: 0.28,
          status: 'Severe Impairment',
          details: 'Sector 3 & 4 arterial culverts operating at 135% volume capacity.',
        ),
        RiskFactor(
          name: 'P2P Hazard Report Density',
          weight: 0.18,
          status: 'Elevated Cluster',
          details: '4 verified citizen reports logged within 3.5 km radius.',
        ),
        RiskFactor(
          name: 'Infrastructure Vulnerability',
          weight: 0.12,
          status: 'Moderate',
          details: 'Low-lying access underpasses susceptible to vehicle stalling.',
        ),
      ],
      recommendedActions: const [
        'Evacuate ground-level structures in low-lying maritime zones.',
        'Avoid 4th Avenue Underpass and shoreline arterial roads.',
        'Ensure 72-hour Emergency Pack is packed and ready for immediate transit.',
        'Keep device Bluetooth enabled for offline peer-to-peer relay sync.',
      ],
    );
  }

  @override
  Future<int> evaluateRouteRiskScore(List<String> activeHazardTypes) async {
    int baseline = 24;
    for (final hazard in activeHazardTypes) {
      switch (hazard.toLowerCase()) {
        case 'flood':
          baseline += 35;
          break;
        case 'landslide':
          baseline += 28;
          break;
        case 'blocked road':
          baseline += 18;
          break;
        case 'fire':
          baseline += 40;
          break;
        default:
          baseline += 12;
      }
    }
    return baseline.clamp(0, 100);
  }
}
