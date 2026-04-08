import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/bill_model.dart';

class BillService {
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

  static Future<List<BillModel>> getBills() async {
    try {
      final response = await DioClient.dio.get(
        '/bills',
        options: await _authOptions(),
      );

      final responseData = response.data;
      final List billsJson = responseData['data'] ?? [];

      return billsJson.map((item) => BillModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<BillModel>> getBillsByMember(int memberId) async {
    try {
      final response = await DioClient.dio.get(
        '/bills/member/$memberId',
        options: await _authOptions(),
      );

      final responseData = response.data;
      final List billsJson = responseData['data'] ?? [];

      return billsJson.map((item) => BillModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> generateBills({
    required int month,
    required int year,
    String? memberIdentifier,
  }) async {
    try {
      final payload = {
        'month': month,
        'year': year,
        if (memberIdentifier != null && memberIdentifier.isNotEmpty)
          'memberId': memberIdentifier,
      };

      await DioClient.dio.post(
        '/bills/generate',
        data: payload,
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> updateBill({
    required int id,
    required double extraCharges,
    required double paidAmount,
    required String paymentStatus,
  }) async {
    try {
      await DioClient.dio.put(
        '/bills/$id',
        data: {
          'extraCharges': extraCharges,
          'paidAmount': paidAmount,
          'paymentStatus': paymentStatus,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
