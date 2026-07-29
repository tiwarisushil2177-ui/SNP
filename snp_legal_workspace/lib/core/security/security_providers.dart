import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/secure_storage_service.dart';
import 'biometric_lock_service.dart';

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

final biometricLockServiceProvider = Provider<BiometricLockService>((ref) {
  return BiometricLockService(ref.watch(secureStorageProvider));
});

class AppLockState {
  const AppLockState({
    this.lockEnabled = false,
    this.unlocked = true,
    this.checking = true,
  });

  final bool lockEnabled;
  final bool unlocked;
  final bool checking;

  AppLockState copyWith({
    bool? lockEnabled,
    bool? unlocked,
    bool? checking,
  }) {
    return AppLockState(
      lockEnabled: lockEnabled ?? this.lockEnabled,
      unlocked: unlocked ?? this.unlocked,
      checking: checking ?? this.checking,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier(this._lock) : super(const AppLockState()) {
    _init();
  }

  final BiometricLockService _lock;

  Future<void> _init() async {
    final enabled = await _lock.isLockEnabled();
    final unlocked = await _lock.isSessionUnlocked();
    state = AppLockState(
      lockEnabled: enabled,
      unlocked: unlocked || !enabled,
      checking: false,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await _lock.setLockEnabled(enabled);
    state = state.copyWith(
      lockEnabled: enabled,
      unlocked: !enabled || state.unlocked,
    );
  }

  Future<bool> unlock() async {
    final ok = await _lock.authenticate();
    if (ok) {
      state = state.copyWith(unlocked: true);
    }
    return ok;
  }

  Future<void> lock() async {
    await _lock.lockSession();
    if (state.lockEnabled) {
      state = state.copyWith(unlocked: false);
    }
  }
}

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  return AppLockNotifier(ref.watch(biometricLockServiceProvider));
});
