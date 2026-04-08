class MemberModel {
  final int id;
  final String fullName;
  final String? email;
  final String? cmsId;
  final String? phone;
  final String role;
  final String status;
  final int? roomId;
  final String? joiningDate;

  MemberModel({
    required this.id,
    required this.fullName,
    this.email,
    this.cmsId,
    this.phone,
    required this.role,
    required this.status,
    this.roomId,
    this.joiningDate,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      cmsId: json['cmsId'],
      phone: json['phone'],
      role: json['role'] ?? 'MEMBER',
      status: json['status'] ?? 'ACTIVE',
      roomId: json['roomId'],
      joiningDate: json['joiningDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'cmsId': cmsId,
      'phone': phone,
      'role': role,
      'status': status,
      'roomId': roomId,
      'joiningDate': joiningDate,
    };
  }
}
