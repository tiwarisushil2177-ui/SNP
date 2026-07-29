import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'secure_storage_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.userId,
    this.refreshToken,
    this.advocateName,
  });

  final String accessToken;
  final String userId;
  final String? refreshToken;
  final String? advocateName;
}

/// HTTP client with secure token injection and error mapping.
/// Secrets are never embedded in the client — only runtime tokens from secure storage.
class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(AppConstants.keyAccessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: AuthException(
                  'Session expired. Please sign in again.',
                  code: 'unauthorized',
                ),
                type: error.type,
                response: error.response,
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  final SecureStorageService _storage;
  late final Dio _dio;

  Future<bool> validateSession(String token) async {
    try {
      final res = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = res.data as Map<String, dynamic>;
      return AuthResult(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
        userId: data['user_id'] as String,
        advocateName: data['advocate_name'] as String?,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      String message = 'Sign in failed. Please try again.';
      if (status == 401 || status == 403) {
        message = 'Invalid email or password.';
      } else if (status == 429) {
        message = 'Too many attempts. Please wait and try again.';
      } else if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      }
      throw AuthException(message, code: status?.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
  }

  Future<AuthResult> createWorkspace({
    required String email,
    required String password,
    required String fullName,
    required String barCouncilId,
    required String practiceState,
    String? phone,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'bar_council_id': barCouncilId,
          'practice_state': practiceState,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );

      final data = res.data as Map<String, dynamic>;
      return AuthResult(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
        userId: data['user_id'] as String,
        advocateName: fullName,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      String message = 'Could not create workspace. Please try again.';
      if (status == 409) {
        message = 'An account with this email already exists.';
      } else if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      }
      throw AuthException(message, code: status?.toString());
    }
  }

  Dio get dio => _dio;
}
