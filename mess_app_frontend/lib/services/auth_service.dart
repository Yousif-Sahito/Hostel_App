import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  /// Base URL for API - Updated to Render Production Server
  /// Live Render Backend: https://messapp-backend-z05q.onrender.com/api
  static const String _baseUrl = 'https://messapp-backend-z05q.onrender.com/api'; // Production Render URL
  static const String _tokenKey = 'auth_token';

  // Update FCM token
  static Future<void> updateFCMToken(String fcmToken) async {
    try {
      if (fcmToken.isEmpty) {
        throw Exception('FCM token is empty');
      }

      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: _tokenKey);
      
      if (token == null || token.isEmpty) {
        debugPrint('No authentication token found. FCM token not updated.');
        return;
      }

      final dio = Dio();
      final response = await dio.post(
        '$_baseUrl/auth/update-fcm-token',
        data: {'fcmToken': fcmToken},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token updated successfully on backend');
      } else {
        debugPrint('❌ Failed to update FCM token: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException updating FCM token: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }
}
