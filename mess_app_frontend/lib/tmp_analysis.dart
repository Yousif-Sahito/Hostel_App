import 'package:mess_app_frontend/features/auth/services/auth_service.dart';

void main() {
  AuthService.register(
    fullName: 'x',
    email: 'x',
    password: 'p',
    role: 'member',
    hostelName: 'h',
  );
}
