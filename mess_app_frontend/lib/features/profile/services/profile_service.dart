import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';

class ProfileService {
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

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await DioClient.dio.post(
        '/auth/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
