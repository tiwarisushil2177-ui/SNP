class AppConstants {
  AppConstants._();

  static const String appName = 'SNP Legal Workspace';
  static const String appTagline =
      'Secure access to your legal practice workspace';

  // Default local core API. Override: --dart-define=API_BASE_URL=https://…
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8090',
  );

  static const String keyAccessToken = 'snp_access_token';
  static const String keyRefreshToken = 'snp_refresh_token';
  static const String keyUserId = 'snp_user_id';
  static const String keyBiometricEnabled = 'snp_biometric_enabled';

  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static const int minPasswordLength = 8;
}
