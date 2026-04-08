import 'package:flutter/material.dart';

import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<PaymentModel> payments = [];
  List<PaymentModel> filteredPayments = [];

  Future<void> fetchPaymentsByMember(int memberId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      payments = await PaymentService.getPaymentsByMember(memberId);
      filteredPayments = [...payments];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchAllPayments() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      payments = await PaymentService.getAllPayments();
      filteredPayments = [...payments];

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void searchPayments(String query) {
    if (query.trim().isEmpty) {
      filteredPayments = [...payments];
    } else {
      final q = query.toLowerCase();
      filteredPayments = payments.where((payment) {
        return (payment.userName ?? '').toLowerCase().contains(q) ||
          (payment.userEmail ?? '').toLowerCase().contains(q) ||
          (payment.userCmsId ?? '').toLowerCase().contains(q) ||
          payment.paymentMethod.toLowerCase().contains(q) ||
          payment.paymentDate.toLowerCase().contains(q) ||
          (payment.referenceNo ?? '').toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }
}
