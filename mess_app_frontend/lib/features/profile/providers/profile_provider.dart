import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isChangingPassword = false;
  String? errorMessage;
  String? successMessage;
  ProfileModel? profile;

  void setProfile(ProfileModel profileData) {
    profile = profileData;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      isChangingPassword = true;
      errorMessage = null;
      successMessage = null;
      notifyListeners();

      await ProfileService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      isChangingPassword = false;
      successMessage = 'Password changed successfully';
      notifyListeners();
      return true;
    } catch (e) {
      isChangingPassword = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}
