import 'package:flutter/material.dart';

import '../models/menu_model.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  MenuModel? currentMenu;

  Future<void> fetchCurrentWeekMenu() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      currentMenu = await MenuService.getCurrentWeekMenu();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
