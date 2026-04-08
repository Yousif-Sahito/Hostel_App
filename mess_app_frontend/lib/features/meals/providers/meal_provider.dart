import 'package:flutter/material.dart';

import '../models/meal_model.dart';
import '../services/meal_service.dart';

class MealProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<MealModel> meals = [];
  List<MealModel> filteredMeals = [];

  Future<void> fetchMeals() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      meals = await MealService.getMeals();
      filteredMeals = [...meals];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchMealsByMember(int memberId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      meals = await MealService.getMealsByMember(memberId);
      filteredMeals = [...meals];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void searchMeals(String query) {
    if (query.trim().isEmpty) {
      filteredMeals = [...meals];
    } else {
      final q = query.toLowerCase();
      filteredMeals = meals.where((meal) {
        return (meal.userName ?? '').toLowerCase().contains(q) ||
            meal.mealDate.toLowerCase().contains(q) ||
            meal.guestCount.toString().contains(q);
      }).toList();
    }
    notifyListeners();
  }
}
