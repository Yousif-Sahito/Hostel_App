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

      final authToken = await SecureStorageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('No auth token found for FCM update.');
        return;
      }

      await DioClient.dio.post(
        '/auth/update-fcm-token',
        data: {'fcmToken': token},
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
    } catch (e) {
      debugPrint('FCM token update failed: $e');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required String role,
    required String hostelName,
  }) async {
    try {
      final Response response = await DioClient.dio.post(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'email': email,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone,
          'password': password,
          'role': role,
          'hostelName': hostelName,
        },
      );

      final responseData = response.data;

      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'];
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>?;

        if (token == null || userJson == null) {
          throw Exception('Invalid registration response format');
        }

        final user = UserModel.fromJson(userJson);

        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveRole(user.role);
        await SecureStorageService.saveUserName(user.fullName);

        return {'token': token, 'user': user};
      }

      throw Exception(responseData['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data?['message'] ?? 'Server error during registration',
        );
      }
      throw Exception('Unable to connect to backend');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> forgotPassword(String email) async {
    try {
      final Response response = await DioClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );

      final responseData = response.data;
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to send reset link');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data?['message'] ?? 'Server error during password reset request',
        );
      }
      throw Exception('Unable to connect to backend');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final Response response = await DioClient.dio.post(
        '/auth/reset-password',
        data: {
          'token': token.trim(),
          'newPassword': newPassword.trim(),
        },
      );

      final responseData = response.data;
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to reset password');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data?['message'] ?? 'Server error during password reset',
        );
      }
      throw Exception('Unable to connect to backend');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> verifyEmail(String token) async {
    try {
      final Response response = await DioClient.dio.post(
        '/auth/verify-email',
        data: {'token': token.trim()},
      );

      final responseData = response.data;
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to verify email');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data?['message'] ?? 'Server error during email verification',
        );
      }
      throw Exception('Unable to connect to backend');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> resendVerificationEmail(String email) async {
    try {
      final Response response = await DioClient.dio.post(
        '/auth/resend-verification',
        data: {'email': email.trim()},
      );

      final responseData = response.data;
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to resend verification email');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data?['message'] ?? 'Server error during verification email sending',
        );
      }
      throw Exception('Unable to connect to backend');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> deleteAccount() async {
    try {
      final authToken = await SecureStorageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      final Response response = await DioClient.dio.delete(
        '/auth/delete-account',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      final responseData = response.data;
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to delete account');
      }

      await SecureStorageService.clear();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data?['message'] ?? 'Server error during account deletion',
        );
      }
      throw Exception('Unable to connect to backend');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
