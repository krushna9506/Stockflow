/// Centralized API endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';

  // Core Data
  static const String businesses = '/businesses';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String transactions = '/transactions';

  // Sync & Updates
  static const String sync = '/sync';
  static const String updateCheck = '/update/check';
}
