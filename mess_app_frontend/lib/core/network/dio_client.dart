import 'package:dio/dio.dart';
import '../../app/constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  static final Dio dio = _initializeDio();

  static Dio _initializeDio() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Add interceptor to attach token to all requests
    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await SecureStorageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // Continue without token if retrieval fails
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle token expiration or 401 errors if needed
          return handler.next(error);
        },
      ),
    );

    return dioInstance;
  }
}
