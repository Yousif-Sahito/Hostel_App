import 'package:dio/dio.dart';

import '../../../app/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/member_model.dart';

class MemberService {
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

  static Future<List<MemberModel>> getMembers() async {
    try {
      final response = await DioClient.dio.get(
        ApiConstants.members,
        options: await _authOptions(),
      );

      final responseData = response.data;
      final List membersJson = responseData['data'] ?? [];

      return membersJson.map((item) => MemberModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<MemberModel> getMemberById(int id) async {
    try {
      final response = await DioClient.dio.get(
        '${ApiConstants.members}/$id',
        options: await _authOptions(),
      );

      final responseData = response.data;
      return MemberModel.fromJson(responseData['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> addMember({
    required String fullName,
    required String email,
    required String cmsId,
    required String phone,
    required String password,
    String role = 'MEMBER',
    String status = 'ACTIVE',
    bool mealUnitEnabled = true,
    int? roomId,
    String? joiningDate,
  }) async {
    try {
      await DioClient.dio.post(
        ApiConstants.members,
        data: {
          'fullName': fullName,
          'email': email,
          'cmsId': cmsId,
          'phone': phone,
          'password': password,
          'role': role,
          'status': status,
          'mealUnitEnabled': mealUnitEnabled,
          'roomId': roomId,
          'joiningDate': joiningDate,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> updateMember({
    required int id,
    required String fullName,
    required String email,
    required String cmsId,
    required String phone,
    String role = 'MEMBER',
    String status = 'ACTIVE',
    bool? mealUnitEnabled,
    int? roomId,
    String? joiningDate,
  }) async {
    try {
      await DioClient.dio.put(
        '${ApiConstants.members}/$id',
        data: {
          'fullName': fullName,
          'email': email,
          'cmsId': cmsId,
          'phone': phone,
          'role': role,
          'status': status,
          'mealUnitEnabled': mealUnitEnabled,
          'roomId': roomId,
          'joiningDate': joiningDate,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> deleteMember(int id) async {
    try {
      await DioClient.dio.delete(
        '${ApiConstants.members}/$id',
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
