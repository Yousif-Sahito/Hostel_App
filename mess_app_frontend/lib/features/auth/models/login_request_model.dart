class LoginRequestModel {
  final String? email;
  final String? cmsId;
  final String password;

  LoginRequestModel({this.email, this.cmsId, required this.password});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'password': password};

    if (email != null && email!.trim().isNotEmpty) {
      data['email'] = email;
    }

    if (cmsId != null && cmsId!.trim().isNotEmpty) {
      data['cmsId'] = cmsId;
    }

    return data;
  }
}
