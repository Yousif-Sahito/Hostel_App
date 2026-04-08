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
    String? email,
    String? cmsId,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await AuthService.login(
        LoginRequestModel(email: email, cmsId: cmsId, password: password),
      );

      token = result['token'] as String;
      currentUser = result['user'] as UserModel;

      // Send FCM token to backend after successful login
      try {
        final fcmToken = await FCMService().getToken();
        if (fcmToken != null) {
          await AuthService.updateFCMToken(fcmToken);
        }
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
        // Don't fail login if FCM token update fails
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

  Future<void> logout() async {
    token = null;
    currentUser = null;
    errorMessage = null;
    await SecureStorageService.clear();
    notifyListeners();
  }
}
