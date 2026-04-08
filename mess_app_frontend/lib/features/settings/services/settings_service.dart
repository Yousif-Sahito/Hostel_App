import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/settings_model.dart';

class SettingsService {
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

  static Future<SettingsModel> getSettings() async {
    try {
      final response = await DioClient.dio.get(
        '/settings',
        options: await _authOptions(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        if (data['data'] is Map<String, dynamic>) {
          return SettingsModel.fromJson(data['data']);
        }

        return SettingsModel.fromJson(data);
      }

      throw Exception('Invalid settings response');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<SettingsModel> updateSettings(SettingsModel settings) async {
    try {
      final response = await DioClient.dio.put(
        '/settings',
        data: settings.toJson(),
        options: await _authOptions(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        if (data['data'] is Map<String, dynamic>) {
          return SettingsModel.fromJson(data['data']);
        }

        return SettingsModel.fromJson(data);
      }

      throw Exception('Invalid update response');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
