import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/meal_model.dart';

class MealService {
  static Future<Options> _authOptions() async {
    final token = await SecureStorageService.getToken();

    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  static Exception _handleError(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message != null) {
        return Exception(message.toString());
      }
    }

    return Exception('Something went wrong');
  }

  static Future<List<MealModel>> getMeals() async {
    try {
      final response = await DioClient.dio.get(
        '/meals',
        options: await _authOptions(),
      );

      final responseData = response.data;
      final List mealsJson = responseData['data'] ?? [];

      return mealsJson.map((item) => MealModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<MealModel>> getMealsByMember(int memberId) async {
    try {
      final response = await DioClient.dio.get(
        '/meals/member/$memberId',
        options: await _authOptions(),
      );

      final responseData = response.data;
      final List mealsJson = responseData['data'] ?? [];

      return mealsJson.map((item) => MealModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> addMeal({
    required int userId,
    required String mealDate,
    required bool breakfastTaken,
    required bool lunchTaken,
    required bool dinnerTaken,
    required int guestCount,
  }) async {
    try {
      await DioClient.dio.post(
        '/meals',
        data: {
          'userId': userId,
          'date': mealDate,
          'breakfast': breakfastTaken,
          'lunch': lunchTaken,
          'dinner': dinnerTaken,
          'guestCount': guestCount,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> updateMeal({
    required int id,
    required int userId,
    required String mealDate,
    required bool breakfastTaken,
    required bool lunchTaken,
    required bool dinnerTaken,
    required int guestCount,
  }) async {
    try {
      await DioClient.dio.put(
        '/meals/$id',
        data: {
          'userId': userId,
          'date': mealDate,
          'breakfast': breakfastTaken,
          'lunch': lunchTaken,
          'dinner': dinnerTaken,
          'guestCount': guestCount,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> deleteMeal(int id) async {
    try {
      await DioClient.dio.delete('/meals/$id', options: await _authOptions());
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> bulkRecordMeals({
    required String mealDate,
    required List<Map<String, dynamic>> meals,
  }) async {
    try {
      await DioClient.dio.post(
        '/meals/bulk',
        data: {
          'date': mealDate,
          'meals': meals,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
