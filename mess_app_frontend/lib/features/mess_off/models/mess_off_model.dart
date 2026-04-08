class MessOffModel {
  final int? id;
  final int userId;
  final String? userName;
  final String? cmsId;
  final String fromDate;
  final String toDate;
  final String? reason;
  final String status;
  final String? createdAt;

  MessOffModel({
    this.id,
    required this.userId,
    this.userName,
    this.cmsId,
    required this.fromDate,
    required this.toDate,
    this.reason,
    required this.status,
    this.createdAt,
  });

  factory MessOffModel.fromJson(Map<String, dynamic> json) {
    return MessOffModel(
      id: json['id'] as int?,
      userId: (json['userId'] ?? json['memberId'] ?? 0) as int,
      userName:
          json['user']?['fullName']?.toString() ??
          json['member']?['fullName']?.toString() ??
          json['userName']?.toString(),
      cmsId: json['user']?['cmsId']?.toString() ?? json['cmsId']?.toString(),
      fromDate: json['fromDate']?.toString() ?? '',
      toDate: json['toDate']?.toString() ?? '',
      reason: json['reason']?.toString(),
      status: (json['status']?.toString() ?? 'ACTIVE').toUpperCase(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fromDate': fromDate,
      'toDate': toDate,
      'reason': reason,
      'status': status,
    };
  }
}
