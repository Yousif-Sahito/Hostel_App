import 'package:dio/dio.dart';

import '../../../app/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/room_model.dart';

class RoomService {
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

  static Future<List<RoomModel>> getRooms() async {
    try {
      final response = await DioClient.dio.get(
        ApiConstants.rooms,
        options: await _authOptions(),
      );

      final responseData = response.data;
      final List roomsJson = responseData['data'] ?? [];

      return roomsJson.map((item) => RoomModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<RoomModel> getRoomById(int id) async {
    try {
      final response = await DioClient.dio.get(
        '${ApiConstants.rooms}/$id',
        options: await _authOptions(),
      );

      final responseData = response.data;
      return RoomModel.fromJson(responseData['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> addRoom({
    required String roomNumber,
    required int capacity,
    String status = 'AVAILABLE',
  }) async {
    try {
      await DioClient.dio.post(
        ApiConstants.rooms,
        data: {
          'roomNumber': roomNumber,
          'capacity': capacity,
          'status': status,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> updateRoom({
    required int id,
    required String roomNumber,
    required int capacity,
    required int occupiedCount,
    required String status,
  }) async {
    try {
      await DioClient.dio.put(
        '${ApiConstants.rooms}/$id',
        data: {
          'roomNumber': roomNumber,
          'capacity': capacity,
          'occupiedCount': occupiedCount,
          'status': status,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> deleteRoom(int id) async {
    try {
      await DioClient.dio.delete(
        '${ApiConstants.rooms}/$id',
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
