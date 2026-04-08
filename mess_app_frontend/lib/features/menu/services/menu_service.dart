import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/menu_model.dart';

class MenuService {
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

  static Future<MenuModel?> getCurrentWeekMenu() async {
    try {
      final response = await DioClient.dio.get(
        '/menu/current-week',
        options: await _authOptions(),
      );

      final responseData = response.data;
      final data = responseData['data'];

      if (data == null) return null;

      return MenuModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> createMenu({
    required String weekStartDate,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await DioClient.dio.post(
        '/menu',
        data: {'weekStartDate': weekStartDate, 'items': items},
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> updateMenu({
    required int id,
    required String weekStartDate,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await DioClient.dio.put(
        '/menu/$id',
        data: {'weekStartDate': weekStartDate, 'items': items},
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
