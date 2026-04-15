import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/payment_model.dart';

class PaymentService {
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

  static Future<List<PaymentModel>> getPaymentsByMember(int memberId) async {
    try {
      final response = await DioClient.dio.get(
        '/payments/member/$memberId',
        options: await _authOptions(),
      );

      final responseData = response.data;
      final List paymentsJson = responseData['data'] ?? [];

      return paymentsJson.map((item) => PaymentModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<PaymentModel>> getAllPayments() async {
    try {
      final response = await DioClient.dio.get(
        '/payments',
        options: await _authOptions(),
      );

      final responseData = response.data;
      final List paymentsJson = responseData['data'] ?? [];

      return paymentsJson.map((item) => PaymentModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> addPayment({
    required int billId,
    required int userId,
    required double amount,
    required String paymentMethod,
    required String paymentDate,
    String paymentType = 'REGULAR',
    String? referenceNo,
    String? notes,
  }) async {
    try {
      final response = await DioClient.dio.post(
        '/payments',
        data: {
          'billId': billId,
          'userId': userId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'paymentDate': paymentDate,
          'paymentType': paymentType,
          'referenceNo': referenceNo,
          'notes': notes,
        },
        options: await _authOptions(),
      );
      return response.data['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
