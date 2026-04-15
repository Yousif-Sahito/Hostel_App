import 'features/auth/services/auth_service.dart';

void main() {
  AuthService.register(
    fullName: 'x',
    email: 'x',
    password: 'p',
    role: 'member',
    hostelName: 'h',
  );
}
