import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/admin_dashboard_model.dart';
import '../models/member_dashboard_model.dart';

class DashboardService {
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

  static Future<AdminDashboardModel> getAdminDashboard() async {
    try {
      final response = await DioClient.dio.get(
        '/dashboard/admin',
        options: await _authOptions(),
      );

      final data = response.data;

      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        return AdminDashboardModel.fromJson(data['data']);
      }

      throw Exception('Invalid admin dashboard response');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MemberDashboardModel> getMemberDashboard() async {
    try {
      final response = await DioClient.dio.get(
        '/dashboard/member',
        options: await _authOptions(),
      );

      final data = response.data;

      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        return MemberDashboardModel.fromJson(data['data']);
      }

      throw Exception('Invalid member dashboard response');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
