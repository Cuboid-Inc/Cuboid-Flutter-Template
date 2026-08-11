import 'package:cuboid_flutter_template/core/storage/cache_entry.dart';
import 'package:cuboid_flutter_template/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

class _CacheOwner with RepositoryCacheMixin {}

void main() {
  test('freshness uses the supplied TTL', () {
    final fresh = CacheEntry<int>(
      value: 1,
      storedAt: DateTime.now().subtract(const Duration(seconds: 30)),
    );

    expect(fresh.isFresh(const Duration(minutes: 1)), isTrue);
  });

  test('cached stores a success and reuses it', () async {
    final owner = _CacheOwner();
    final cache = <String, CacheEntry<Object>>{};
    var loads = 0;

    Future<Result<int>> load() async => Success(++loads);

    expect((await owner.cached(cache, 'value', load) as Success<int>).value, 1);
    expect((await owner.cached(cache, 'value', load) as Success<int>).value, 1);
    expect(loads, 1);
    owner.clearCache(cache);
    expect(cache, isEmpty);
  });
}
