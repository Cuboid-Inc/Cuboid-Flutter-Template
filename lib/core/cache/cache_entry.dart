import 'package:cuboid_flutter_template/core/result.dart';

/// A generic in-memory cache entry with TTL support.
class CacheEntry<T> {
  final T value;
  final DateTime storedAt;
  static const Duration defaultTtl = Duration(minutes: 1);

  const CacheEntry({required this.value, required this.storedAt});
  factory CacheEntry.now(T value) =>
      CacheEntry(value: value, storedAt: DateTime.now());

  bool isFresh([Duration? ttl]) =>
      DateTime.now().difference(storedAt) <= (ttl ?? defaultTtl);
}

mixin RepositoryCacheMixin {
  Future<Result<T>> cached<T extends Object>(
    Map<String, CacheEntry<Object>> cache,
    String key,
    Future<Result<T>> Function() load,
  ) async {
    final entry = cache[key];
    if (entry?.isFresh() ?? false) return Success(entry!.value as T);
    final result = await load();
    if (result case Success<T>(:final value)) {
      cache[key] = CacheEntry<Object>.now(value);
    }
    return result;
  }

  void clearCache<T>(Map<String, CacheEntry<T>> cache) => cache.clear();
}
