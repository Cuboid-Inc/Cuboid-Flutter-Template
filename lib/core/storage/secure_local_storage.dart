import 'package:nemara_homes/core/constants/storage_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(
      storageNamespace: StorageKeys.authStorageNamespace,
    ),
  );

  const SecureLocalStorage();

  @override
  Future<String?> accessToken() =>
      _storage.read(key: StorageKeys.supabaseSession);

  @override
  Future<bool> hasAccessToken() =>
      _storage.containsKey(key: StorageKeys.supabaseSession);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistSession(String persistSessionString) => _storage.write(
    key: StorageKeys.supabaseSession,
    value: persistSessionString,
  );

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: StorageKeys.supabaseSession);
}
