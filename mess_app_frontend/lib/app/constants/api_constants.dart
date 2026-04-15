import '../../config/app_environment.dart';

class ApiConstants {
  static final String baseUrl = AppEnvironment.apiBaseUrl;

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const members = '/members';
  static const rooms = '/rooms';
  static const settings = '/settings';

  static const changePassword = '/auth/change-password';
}
