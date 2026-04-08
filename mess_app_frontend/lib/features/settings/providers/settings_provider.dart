import 'package:flutter/material.dart';

import '../models/settings_model.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  SettingsModel? settings;

  Future<void> fetchSettings() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      settings = await SettingsService.getSettings();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings(SettingsModel updatedSettings) async {
    try {
      isSaving = true;
      errorMessage = null;
      successMessage = null;
      notifyListeners();

      settings = await SettingsService.updateSettings(updatedSettings);
      successMessage = 'Settings updated successfully';
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}
