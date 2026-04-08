import 'package:flutter/material.dart';

import '../models/room_model.dart';
import '../services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<RoomModel> rooms = [];
  List<RoomModel> filteredRooms = [];

  Future<void> fetchRooms() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      rooms = await RoomService.getRooms();
      filteredRooms = [...rooms];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void searchRooms(String query) {
    if (query.trim().isEmpty) {
      filteredRooms = [...rooms];
    } else {
      final q = query.toLowerCase();
      filteredRooms = rooms.where((room) {
        return room.roomNumber.toLowerCase().contains(q) ||
            room.status.toLowerCase().contains(q) ||
            room.capacity.toString().contains(q) ||
            room.occupiedCount.toString().contains(q);
      }).toList();
    }

    notifyListeners();
  }
}
