import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/report_provider.dart';
import 'providers/emergency_pack_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/bluetooth_service.dart';
import 'services/local_storage_service.dart';
import 'screens/splash/splash_screen.dart';

class LastSignalApp extends StatelessWidget {
  const LastSignalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = LocalStorageService();
    final apiService = ApiService();
    final authService = AuthService(storageService, apiService);
    final bluetoothService = BluetoothService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(apiService),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService, storageService)..init(),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (_) => ReportProvider(storageService, apiService)..init(),
        ),
        ChangeNotifierProvider<EmergencyPackProvider>(
          create: (_) => EmergencyPackProvider(storageService, apiService)..init(),
        ),
        ChangeNotifierProvider<BluetoothProvider>(
          create: (_) => BluetoothProvider(bluetoothService, storageService)..init(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(storageService, apiService)..init(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
