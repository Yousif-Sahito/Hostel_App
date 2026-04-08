import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/mess_off_model.dart';

class MessOffService {
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

  static Future<List<MessOffModel>> getMessOffEntries() async {
    try {
      final response = await DioClient.dio.get(
        '/messoff',
        options: await _authOptions(),
      );

      final List items = response.data['data'] ?? [];
      return items.map((item) => MessOffModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Use this only if your backend actually supports /mess-off/member/:id
  static Future<List<MessOffModel>> getMessOffEntriesByMember(
    int memberId,
  ) async {
    try {
      final response = await DioClient.dio.get(
        '/messoff/member/$memberId',
        options: await _authOptions(),
      );

      final List items = response.data['data'] ?? [];
      return items.map((item) => MessOffModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> addMessOff({
    required int userId,
    required String fromDate,
    required String toDate,
    String? reason,
    String status = 'ACTIVE',
  }) async {
    try {
      await DioClient.dio.post(
        '/messoff',
        data: {
          'userId': userId,
          'fromDate': fromDate,
          'toDate': toDate,
          'reason': reason,
          'status': status,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> updateMessOff({
    required int id,
    required int userId,
    required String fromDate,
    required String toDate,
    String? reason,
    required String status,
  }) async {
    try {
      await DioClient.dio.put(
        '/messoff/$id',
        data: {
          'userId': userId,
          'fromDate': fromDate,
          'toDate': toDate,
          'reason': reason,
          'status': status,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> deleteMessOff(int id) async {
    try {
      await DioClient.dio.delete(
        '/messoff/$id',
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<bool> toggleMessStatus() async {
    try {
      final response = await DioClient.dio.post(
        '/messoff/toggle',
        options: await _authOptions(),
      );
      return response.data['isOff'] ?? false;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<MessOffModel>> getTomorrowMessOffList() async {
    try {
      final response = await DioClient.dio.get(
        '/messoff/tomorrow',
        options: await _authOptions(),
      );
      final List items = response.data['data'] ?? [];
      return items.map((item) => MessOffModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
