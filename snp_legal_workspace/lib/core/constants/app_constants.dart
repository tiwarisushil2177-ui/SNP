class AppConstants {
  AppConstants._();

  static const String appName = 'SNP Legal Workspace';
  static const String appTagline = 'Secure access to your legal practice workspace';

  // API — replace with production backend URL. Never hardcode secrets.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.snplegal.workspace',
  );

  // Secure storage keys
  static const String keyAccessToken = 'snp_access_token';
  static const String keyRefreshToken = 'snp_refresh_token';
  static const String keyUserId = 'snp_user_id';
  static const String keyBiometricEnabled = 'snp_biometric_enabled';

  // Validation
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static const int minPasswordLength = 8;
}
