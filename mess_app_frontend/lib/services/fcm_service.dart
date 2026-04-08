import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  FirebaseMessaging? _firebaseMessaging;
  bool _isInitialized = false;
  String? _cachedToken;

  bool get isInitialized => _isInitialized;

  // Initialize Firebase and FCM
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint(
        'ℹ️ Skipping FCM initialization on web because FirebaseOptions are not configured.',
      );
      return;
    }

    try {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;

      // Request notification permissions for iOS
      await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        provisional: false,
        sound: true,
      );

      // Get FCM token and cache it
      _cachedToken = await _firebaseMessaging!.getToken();
      if (kDebugMode) {
        debugPrint('✅ FCM Token: $_cachedToken');
      }

      // Handle notification when app is in foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundNotification);

      // Handle notification when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      _isInitialized = true;
      debugPrint(
        '✅ FCM Service initialized successfully - Initialization complete!',
      );
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
      _isInitialized = false;
    }
  }

  // Get current FCM token
  Future<String?> getToken() async {
    if (!_isInitialized || _firebaseMessaging == null) {
      debugPrint('⚠️ FCMService.getToken called before initialization');
      return null;
    }

    try {
      // Return cached token if available
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        return _cachedToken;
      }

      // Otherwise fetch new token
      _cachedToken = await _firebaseMessaging!.getToken();
      return _cachedToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Listen for token refresh events
  void onTokenRefresh(Function(String) callback) {
    if (!_isInitialized || _firebaseMessaging == null) {
      debugPrint('⚠️ FCMService.onTokenRefresh called before initialization');
      return;
    }

    try {
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        _cachedToken = newToken; // Cache the new token
        callback(newToken);
      });
    } catch (e) {
      debugPrint('❌ Error setting up token refresh listener: $e');
    }
  }

  // Handle foreground notifications
  void _handleForegroundNotification(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📲 Received notification in foreground:');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');
    }

    // You can show a local notification here or handle the data
    // For now, it will just print to console
  }

  // Handle notification click when app is opened from background
  void _handleNotificationClick(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('👆 Notification clicked:');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');
    }

    // Handle navigation based on notification type
    // You can navigate to specific screens based on the type
    // e.g., MESS_OFF, UNPAID_BILL, PAYMENT_RECEIVED
  }

  // Delete token (on logout)
  Future<void> deleteToken() async {
    if (!_isInitialized || _firebaseMessaging == null) {
      debugPrint('⚠️ FCMService.deleteToken called before initialization');
      return;
    }

    try {
      await _firebaseMessaging!.deleteToken();
      _cachedToken = null;
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }
}
