class BillModel {
  final int? id;
  final int userId;
  final String? userName;
  final double userAdvanceBalance;
  final int month;
  final int year;
  final int breakfastUnits;
  final int lunchUnits;
  final int dinnerUnits;
  final int guestUnits;
  final double helperCharge;
  final double extraCharges;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;

  BillModel({
    this.id,
    required this.userId,
    this.userName,
    required this.userAdvanceBalance,
    required this.month,
    required this.year,
    required this.breakfastUnits,
    required this.lunchUnits,
    required this.dinnerUnits,
    required this.guestUnits,
    required this.helperCharge,
    required this.extraCharges,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'],
      userId: json['userId'] ?? 0,
      userName:
          json['user']?['fullName']?.toString() ?? json['userName']?.toString(),
      userAdvanceBalance:
          (json['user']?['advanceBalance'] ?? json['userAdvanceBalance'] ?? 0)
              .toDouble(),
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      breakfastUnits: json['breakfastUnits'] ?? 0,
      lunchUnits: json['lunchUnits'] ?? 0,
      dinnerUnits: json['dinnerUnits'] ?? 0,
      guestUnits: json['guestUnits'] ?? 0,
      helperCharge: (json['helperCharge'] ?? 0).toDouble(),
      extraCharges: (json['extraCharges'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      dueAmount: (json['dueAmount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userAdvanceBalance': userAdvanceBalance,
      'month': month,
      'year': year,
      'breakfastUnits': breakfastUnits,
      'lunchUnits': lunchUnits,
      'dinnerUnits': dinnerUnits,
      'guestUnits': guestUnits,
      'helperCharge': helperCharge,
      'extraCharges': extraCharges,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'paymentStatus': paymentStatus,
    };
  }
}
