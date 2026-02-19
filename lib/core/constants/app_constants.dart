/// App-wide constants.
abstract class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Driving Test Swap';
  static const String appVersion = '1.0.0';

  // API (placeholder – replace with your base URL)
  static const String baseUrl = 'https://api.example.com';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyLocale = 'locale';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingSeen = 'onboarding_seen';

  // Pagination
  static const int defaultPageSize = 20;

  // Animation
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationLong = Duration(milliseconds: 500);
}
