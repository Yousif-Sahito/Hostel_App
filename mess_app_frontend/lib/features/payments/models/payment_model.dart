class PaymentModel {
  final int? id;
  final int billId;
  final int userId;
  final String? userName;
  final String? userEmail;
  final String? userCmsId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String? referenceNo;
  final String? notes;

  PaymentModel({
    this.id,
    required this.billId,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userCmsId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.referenceNo,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      billId: json['billId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName:
          json['user']?['fullName']?.toString() ?? json['userName']?.toString(),
      userEmail:
          json['user']?['email']?.toString() ?? json['userEmail']?.toString(),
      userCmsId:
          json['user']?['cmsId']?.toString() ?? json['userCmsId']?.toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      paymentDate: json['paymentDate']?.toString() ?? '',
      referenceNo: json['referenceNo']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billId': billId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'referenceNo': referenceNo,
      'notes': notes,
    };
  }
}
