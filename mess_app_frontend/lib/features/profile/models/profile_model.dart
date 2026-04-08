class ProfileModel {
  final int id;
  final String fullName;
  final String? email;
  final String? cmsId;
  final String role;
  final String status;

  const ProfileModel({
    required this.id,
    required this.fullName,
    this.email,
    this.cmsId,
    required this.role,
    required this.status,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      cmsId: json['cmsId'],
      role: json['role'] ?? '',
      status: json['status'] ?? '',
    );
  }

  factory ProfileModel.fromAuthUser(dynamic user) {
    return ProfileModel(
      id: user?.id ?? 0,
      fullName: user?.fullName ?? '',
      email: user?.email,
      cmsId: user?.cmsId,
      role: user?.role ?? '',
      status: user?.status ?? '',
    );
  }
}
