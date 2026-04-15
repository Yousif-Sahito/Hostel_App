import 'package:flutter/foundation.dart';

/// Provides the backend base URL for each supported development environment.
class AppEnvironment {
  static String get apiBaseUrl {
    if (kReleaseMode) {
      // In Docker: nginx proxies /api to backend (same origin)
      // For cloud: change this to your deployed backend URL
      return '/api';
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }

    return 'http://10.0.2.2:5000/api';
  }
}
