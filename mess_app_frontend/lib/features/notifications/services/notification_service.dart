import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/notification_item.dart';

class NotificationService {
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

  static Future<List<NotificationItem>> getMyNotifications() async {
    try {
      final response = await DioClient.dio.get(
        '/notifications/my',
        options: await _authOptions(),
      );
      final List items = response.data['data'] ?? [];
      return items
          .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final response = await DioClient.dio.get(
        '/notifications/unread-count',
        options: await _authOptions(),
      );
      return response.data['data']?['unreadCount'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> markAsRead(int id) async {
    try {
      await DioClient.dio.patch(
        '/notifications/$id/read',
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> markAllAsRead() async {
    try {
      await DioClient.dio.patch(
        '/notifications/read-all',
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
