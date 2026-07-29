import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../services/secure_storage_service.dart';

/// App lock via biometrics / device PIN. Tokens stay in secure storage only.
class BiometricLockService {
  BiometricLockService(this._storage, {LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final SecureStorageService _storage;
  final LocalAuthentication _auth;

  static const _lockEnabledKey = 'snp_app_lock_enabled';
  static const _sessionUnlockedKey = 'snp_session_unlocked';

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isLockEnabled() async {
    final v = await _storage.read(_lockEnabledKey);
    return v == '1';
  }

  Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(_lockEnabledKey, enabled ? '1' : '0');
    if (!enabled) {
      await _storage.write(_sessionUnlockedKey, '1');
    } else {
      await _storage.write(_sessionUnlockedKey, '0');
    }
  }

  Future<bool> isSessionUnlocked() async {
    final enabled = await isLockEnabled();
    if (!enabled) return true;
    final v = await _storage.read(_sessionUnlockedKey);
    return v == '1';
  }

  Future<void> lockSession() async {
    if (await isLockEnabled()) {
      await _storage.write(_sessionUnlockedKey, '0');
    }
  }

  Future<bool> authenticate({
    String reason = 'Unlock SNP Legal Workspace',
  }) async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) {
        await _storage.write(_sessionUnlockedKey, '1');
        return true;
      }
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (ok) {
        await _storage.write(_sessionUnlockedKey, '1');
      }
      return ok;
    } on PlatformException {
      return false;
    }
  }
}
