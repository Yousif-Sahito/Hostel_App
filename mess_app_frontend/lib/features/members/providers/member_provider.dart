import 'package:flutter/material.dart';

import '../models/member_model.dart';
import '../services/member_service.dart';

class MemberProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<MemberModel> members = [];
  List<MemberModel> filteredMembers = [];

  Future<void> fetchMembers() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      members = await MemberService.getMembers();
      filteredMembers = [...members];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void searchMembers(String query) {
    if (query.trim().isEmpty) {
      filteredMembers = [...members];
    } else {
      final q = query.toLowerCase();
      filteredMembers = members.where((member) {
        return member.fullName.toLowerCase().contains(q) ||
            (member.email ?? '').toLowerCase().contains(q) ||
            (member.cmsId ?? '').toLowerCase().contains(q) ||
            (member.phone ?? '').toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }
}
