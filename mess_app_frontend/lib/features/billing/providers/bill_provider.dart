import 'package:flutter/material.dart';

import '../models/bill_model.dart';
import '../services/bill_service.dart';

class BillProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<BillModel> bills = [];
  List<BillModel> filteredBills = [];

  Future<void> fetchBills() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      bills = await BillService.getBills();
      filteredBills = [...bills];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchBillsByMember(int memberId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      bills = await BillService.getBillsByMember(memberId);
      filteredBills = [...bills];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void searchBills(String query) {
    if (query.trim().isEmpty) {
      filteredBills = [...bills];
    } else {
      final q = query.toLowerCase();
      filteredBills = bills.where((bill) {
        return (bill.userName ?? '').toLowerCase().contains(q) ||
            bill.month.toString().contains(q) ||
            bill.year.toString().contains(q) ||
            bill.paymentStatus.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }
}
