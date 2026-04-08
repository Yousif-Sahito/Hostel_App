import 'package:flutter/material.dart';

import '../models/mess_off_model.dart';
import '../services/mess_off_service.dart';

class MessOffProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<MessOffModel> entries = [];
  List<MessOffModel> filteredEntries = [];

  Future<void> fetchMessOffEntries() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      entries = await MessOffService.getMessOffEntries();
      filteredEntries = [...entries];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchMessOffEntriesByMember(int memberId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      entries = await MessOffService.getMessOffEntriesByMember(memberId);
      filteredEntries = [...entries];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void searchEntries(String query) {
    if (query.trim().isEmpty) {
      filteredEntries = [...entries];
    } else {
      final q = query.toLowerCase();
      filteredEntries = entries.where((entry) {
        return (entry.userName ?? '').toLowerCase().contains(q) ||
            entry.fromDate.toLowerCase().contains(q) ||
            entry.toDate.toLowerCase().contains(q) ||
            (entry.reason ?? '').toLowerCase().contains(q) ||
            entry.status.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }
}
