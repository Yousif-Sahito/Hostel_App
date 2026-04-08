class UserModel {
  final int id;
  final String fullName;
  final String? email;
  final String? cmsId;
  final String role;
  final String status;

  UserModel({
    required this.id,
    required this.fullName,
    this.email,
    this.cmsId,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      cmsId: json['cmsId'],
      role: json['role'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
