import 'package:flutter/material.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../../../services/fcm_service.dart';
import '../models/login_request_model.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? token;
  UserModel? currentUser;
  String? errorMessage;

  bool get isLoggedIn => token != null && token!.isNotEmpty;
  bool get isAdmin => currentUser?.role.toUpperCase() == 'ADMIN';
  bool get isMember => currentUser?.role.toUpperCase() == 'MEMBER';

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final isEmail = identifier.contains('@');
      final result = await AuthService.login(
        LoginRequestModel(
          email: isEmail ? identifier : null,
          cmsId: isEmail ? null : identifier,
          password: password,
        ),
      );

      token = result['token'] as String;
      currentUser = result['user'] as UserModel;

      try {
        final fcmToken = await FCMService().getToken();
        if (fcmToken != null) {
          await AuthService.updateFCMToken(fcmToken);
        }
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required String role,
    required String hostelName,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await AuthService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
        hostelName: hostelName,
      );

      token = result['token'] as String;
      currentUser = result['user'] as UserModel;

      try {
        final fcmToken = await FCMService().getToken();
        if (fcmToken != null) {
          await AuthService.updateFCMToken(fcmToken);
        }
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await AuthService.forgotPassword(email);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (newPassword != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await AuthService.resetPassword(
        token: token,
        newPassword: newPassword,
      );

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await AuthService.verifyEmail(token);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await AuthService.resendVerificationEmail(email);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await AuthService.deleteAccount();
      token = null;
      currentUser = null;

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    token = null;
    currentUser = null;
    errorMessage = null;
    await SecureStorageService.clear();
    notifyListeners();
  }
}
