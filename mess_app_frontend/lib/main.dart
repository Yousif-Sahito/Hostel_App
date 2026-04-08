import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'services/fcm_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and FCM
  try {
    await FCMService().initialize();
  } catch (e, stackTrace) {
    debugPrint('FCM initialization failed: $e');
    debugPrint(stackTrace.toString());
  }

  runApp(const MessApp());
}

class MessApp extends StatefulWidget {
  const MessApp({super.key});

  @override
  State<MessApp> createState() => _MessAppState();
}

class _MessAppState extends State<MessApp> {
  @override
  void initState() {
    super.initState();
    _setupFCMTokenRefresh();
    _sendInitialFCMToken();
  }

  /// Send the current FCM token to backend on app startup
  Future<void> _sendInitialFCMToken() async {
    try {
      final token = await FCMService().getToken();
      if (token != null && token.isNotEmpty) {
        await AuthService.updateFCMToken(token);
      }
    } catch (e) {
      debugPrint('Error sending initial FCM token: $e');
    }
  }

  /// Listen for FCM token refresh and send new token to backend
  void _setupFCMTokenRefresh() {
    FCMService().onTokenRefresh((newToken) async {
      debugPrint('🔄 FCM token refreshed: $newToken');
      try {
        // Send the new token to backend
        await AuthService.updateFCMToken(newToken);
      } catch (e) {
        debugPrint('❌ Error updating refreshed FCM token on backend: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Hostel Mess Management',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
