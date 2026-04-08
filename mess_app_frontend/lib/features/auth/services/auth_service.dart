import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../app/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/login_request_model.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(LoginRequestModel request) async {
    try {
      final Response response = await DioClient.dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      final responseData = response.data;

      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'];
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>?;

        if (token == null || userJson == null) {
          throw Exception('Invalid login response format');
        }

        final user = UserModel.fromJson(userJson);

        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveRole(user.role);
        await SecureStorageService.saveUserName(user.fullName);

        return {'token': token, 'user': user};
      }

      throw Exception(responseData['message'] ?? 'Login failed');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data?['message'] ?? 'Server error during login',
        );
      }
      throw Exception('Unable to connect to backend');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> updateFCMToken(String token) async {
    try {
      if (token.isEmpty) return;

      await DioClient.dio.post(
        '/auth/update-fcm-token',
        data: {'token': token},
      );
    } catch (e) {
      // Silently fail - not critical for app functionality
      debugPrint('FCM token update failed: $e');
    }
  }
}

