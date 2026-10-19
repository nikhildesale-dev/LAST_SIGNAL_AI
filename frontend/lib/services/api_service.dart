import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hazard_report.dart';
import 'risk_service.dart';

enum BackendStatus {
  connected,
  connecting,
  offline,
  error,
}

class BackendHealthResult {
  final bool isHealthy;
  final String message;
  final int? pingMs;
  final String baseUrl;

  const BackendHealthResult({
    required this.isHealthy,
    required this.message,
    this.pingMs,
    required this.baseUrl,
  });
}

/// Service layer for communicating with LAST SIGNAL AI backend.
/// Supports configurable base URL, timeout management, offline fallback,
/// and transparent reporting of live vs. simulated AI model results.
class ApiService {
  static const String keyBackendUrl = 'ls_backend_base_url';
  static const String defaultLocalUrl = 'http://localhost:8000';
  static const String defaultEmulatorUrl = 'http://10.0.2.2:8000';

  String _baseUrl = defaultLocalUrl;
  BackendStatus _status = BackendStatus.offline;
  int? _lastPingMs;
  String? _lastError;

  String get baseUrl => _baseUrl;
  BackendStatus get status => _status;
  int? get lastPingMs => _lastPingMs;
  String? get lastError => _lastError;
  bool get isConnected => _status == BackendStatus.connected;

  ApiService() {
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(keyBackendUrl);
      if (saved != null && saved.trim().isNotEmpty) {
        _baseUrl = saved.trim();
      } else {
        // Detect if running on Android device / emulator
        if (Platform.isAndroid) {
          _baseUrl = defaultEmulatorUrl;
        } else {
          _baseUrl = defaultLocalUrl;
        }
      }
    } catch (_) {
      _baseUrl = defaultLocalUrl;
    }
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyBackendUrl, _baseUrl);
    } catch (_) {}
  }

  /// Ping the configured backend to check health and measure latency
  Future<BackendHealthResult> checkBackendHealth() async {
    _status = BackendStatus.connecting;
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse('$_baseUrl/api/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      stopwatch.stop();
      _lastPingMs = stopwatch.elapsedMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _status = BackendStatus.connected;
        _lastError = null;
        return BackendHealthResult(
          isHealthy: true,
          message: 'Connected to backend ($baseUrl)',
          pingMs: _lastPingMs,
          baseUrl: _baseUrl,
        );
      } else {
        _status = BackendStatus.error;
        _lastError = 'HTTP ${response.statusCode}';
        return BackendHealthResult(
          isHealthy: false,
          message: 'Server responded with status ${response.statusCode}',
          pingMs: _lastPingMs,
          baseUrl: _baseUrl,
        );
      }
    } on TimeoutException {
      stopwatch.stop();
      _status = BackendStatus.offline;
      _lastError = 'Connection timed out (4s)';
      return BackendHealthResult(
        isHealthy: false,
        message: 'Timeout contacting $baseUrl. Falling back to offline engine.',
        baseUrl: _baseUrl,
      );
    } catch (e) {
      stopwatch.stop();
      _status = BackendStatus.offline;
      _lastError = e.toString();
      return BackendHealthResult(
        isHealthy: false,
        message: 'Unable to reach backend ($baseUrl). Offline demo mode active.',
        baseUrl: _baseUrl,
      );
    }
  }

  /// Query backend AI risk prediction endpoint if available
  Future<RiskEstimate?> predictDisasterRisk({
    double? lat,
    double? lon,
    String? region,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/predict-risk');
      final payload = jsonEncode({
        'latitude': lat ?? 18.9320,
        'longitude': lon ?? 72.8350,
        'region': region ?? 'Sector 3 Coastal Maritime',
        'timestamp': DateTime.now().toIso8601String(),
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _status = BackendStatus.connected;

        final rawFactors = data['contributingFactors'] as List<dynamic>? ?? [];
        final contributingFactors = rawFactors.map((f) {
          final factorMap = f as Map<String, dynamic>;
          return RiskFactor(
            name: factorMap['name'] as String? ?? 'Environmental Stressor',
            weight: (factorMap['weight'] as num?)?.toDouble() ?? 0.25,
            status: factorMap['status'] as String? ?? 'Active',
            details: factorMap['details'] as String? ?? '',
          );
        }).toList();

        final rawActions = data['recommendedActions'] as List<dynamic>? ?? [];
        final recommendedActions =
            rawActions.map((a) => a.toString()).toList();

        return RiskEstimate(
          score: (data['score'] as num?)?.toInt() ?? 50,
          category: data['category'] as String? ?? 'Moderate',
          modelVersion: data['modelVersion'] as String? ?? 'Live Backend AI Model',
          lastUpdated: DateTime.now(),
          confidenceScore:
              (data['confidenceScore'] as num?)?.toDouble() ?? 0.88,
          dataSource: 'Live AI Model ($_baseUrl)',
          summary: data['summary'] as String? ??
              'Risk prediction synthesized from live backend telemetry.',
          contributingFactors: contributingFactors,
          recommendedActions: recommendedActions,
        );
      }
    } catch (_) {
      // Graceful fallback to local heuristic
    }
    return null;
  }

  /// Submit a single report to live backend
  Future<bool> submitReportToBackend(HazardReport report) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/reports');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(report.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Fetch latest verified reports from live backend
  Future<List<HazardReport>?> fetchReportsFromBackend() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/reports');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => HazardReport.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }
}
