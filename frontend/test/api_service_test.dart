import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:last_signal_ai/services/api_service.dart';
import 'package:last_signal_ai/services/risk_service.dart';
import 'package:last_signal_ai/providers/theme_provider.dart';
import 'package:last_signal_ai/providers/connectivity_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ApiService: Default URL, setBaseUrl, and offline fallback', () async {
    final apiService = ApiService();
    expect(apiService.baseUrl.isNotEmpty, true);

    await apiService.setBaseUrl('http://192.168.1.100:8000');
    expect(apiService.baseUrl, 'http://192.168.1.100:8000');

    // Health check when endpoint is offline gracefully returns offline status without throwing
    final health = await apiService.checkBackendHealth();
    expect(health.isHealthy, false);
    expect(health.baseUrl, 'http://192.168.1.100:8000');
  });

  test('RiskService: Dual-engine fallback transparently uses heuristic when backend is offline', () async {
    final apiService = ApiService();
    final riskService = RiskService(apiService);

    final estimate = await riskService.getAreaRiskEstimate();
    expect(estimate.score, 68);
    expect(estimate.category, 'High');
    expect(estimate.isLiveAi, false);
    expect(estimate.dataSource.contains('Simulated') || estimate.dataSource.contains('Offline'), true);
    expect(estimate.contributingFactors.isNotEmpty, true);
    expect(estimate.recommendedActions.isNotEmpty, true);
  });

  test('ConnectivityProvider: Manages backend URL and network simulation', () async {
    final apiService = ApiService();
    final conn = ConnectivityProvider(apiService);

    expect(conn.isOnline, true);
    conn.simulateOffline();
    expect(conn.isOffline, true);
    conn.simulateWeak();
    expect(conn.isWeak, true);
    conn.simulateOnline();
    expect(conn.isOnline, true);

    await conn.updateBackendUrl('http://10.0.2.2:9000');
    expect(conn.backendUrl, 'http://10.0.2.2:9000');
  });

  test('ThemeProvider: Toggles between Dark and Light theme modes', () async {
    final theme = ThemeProvider();
    expect(theme.themeMode, ThemeMode.dark);
    expect(theme.isDarkMode, true);

    await theme.toggleTheme();
    expect(theme.themeMode, ThemeMode.light);
    expect(theme.isDarkMode, false);

    await theme.setThemeMode(ThemeMode.dark);
    expect(theme.themeMode, ThemeMode.dark);
  });
}
