import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';

class AuthException implements Exception {
  AuthException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.userId,
    this.email,
    this.advocateName,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? email;
  final String? advocateName;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? email,
    String? advocateName,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      advocateName: advocateName ?? this.advocateName,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage, this._api) : super(const AuthState()) {
    _restoreSession();
  }

  final SecureStorageService _storage;
  final ApiClient _api;

  Future<void> _restoreSession() async {
    try {
      final token = await _storage.read(AppConstants.keyAccessToken);
      final userId = await _storage.read(AppConstants.keyUserId);
      if (token != null && token.isNotEmpty && userId != null) {
        final valid = await _api.validateSession(token);
        if (valid) {
          state = AuthState(
            isAuthenticated: true,
            isLoading: false,
            userId: userId,
          );
          return;
        }
      }
    } catch (_) {}
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _api.signIn(email: email, password: password);
      await _storage.write(AppConstants.keyAccessToken, result.accessToken);
      if (result.refreshToken != null) {
        await _storage.write(AppConstants.keyRefreshToken, result.refreshToken!);
      }
      await _storage.write(AppConstants.keyUserId, result.userId);
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userId: result.userId,
        email: email,
        advocateName: result.advocateName,
      );
    } on AuthException {
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw AuthException(
        'Unable to connect. Please check your network and try again.',
        code: 'network_error',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _api.signOut();
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  Future<void> createWorkspace({
    required String email,
    required String password,
    required String fullName,
    required String barCouncilId,
    required String practiceState,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _api.createWorkspace(
        email: email,
        password: password,
        fullName: fullName,
        barCouncilId: barCouncilId,
        practiceState: practiceState,
        phone: phone,
      );
      await _storage.write(AppConstants.keyAccessToken, result.accessToken);
      if (result.refreshToken != null) {
        await _storage.write(AppConstants.keyRefreshToken, result.refreshToken!);
      }
      await _storage.write(AppConstants.keyUserId, result.userId);
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userId: result.userId,
        email: email,
        advocateName: fullName,
      );
    } on AuthException {
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw AuthException(
        'Unable to create workspace. Please try again.',
        code: 'network_error',
      );
    }
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(secureStorageProvider),
    ref.watch(apiClientProvider),
  );
});
