import 'package:flutter/material.dart';

import '../../mess_off/services/mess_off_service.dart';
import '../models/admin_dashboard_model.dart';
import '../models/member_dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  bool isLoadingAdmin = false;
  bool isLoadingMember = false;
  bool isTogglingMess = false;

  String? adminErrorMessage;
  String? memberErrorMessage;

  AdminDashboardModel? adminDashboard;
  MemberDashboardModel? memberDashboard;

  Future<void> fetchAdminDashboard() async {
    try {
      isLoadingAdmin = true;
      adminErrorMessage = null;
      notifyListeners();

      adminDashboard = await DashboardService.getAdminDashboard();
    } catch (e) {
      adminErrorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingAdmin = false;
      notifyListeners();
    }
  }

  Future<void> fetchMemberDashboard() async {
    try {
      isLoadingMember = true;
      memberErrorMessage = null;
      notifyListeners();

      memberDashboard = await DashboardService.getMemberDashboard();
    } catch (e) {
      memberErrorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingMember = false;
      notifyListeners();
    }
  }

  Future<void> toggleMessStatus() async {
    try {
      isTogglingMess = true;
      notifyListeners();

      await MessOffService.toggleMessStatus();
      await fetchMemberDashboard();
    } catch (e) {
      throw e.toString().replaceFirst('Exception: ', '');
    } finally {
      isTogglingMess = false;
      notifyListeners();
    }
  }
}
