import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/cache/cache_entry.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/core/supabase/supabase_guard.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoreMenuCounts {
  const MoreMenuCounts({
    required this.customers,
    required this.suppliers,
    required this.vehiclesActive,
    required this.vehiclesExternal,
    required this.drivers,
    required this.agreements,
    required this.routeRates,
    required this.staff,
  });

  final int customers;
  final int suppliers;
  final int vehiclesActive;
  final int vehiclesExternal;
  final int drivers;
  final int agreements;
  final int routeRates;
  final int staff;
}

class MoreRepository with RepositoryCacheMixin {
  MoreRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final Map<String, CacheEntry<Object>> _cache = {};

  String _requireTenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  void invalidateCache() => clearCache(_cache);

  Future<Result<MoreMenuCounts>> fetchMenuCounts() => cached(
    _cache,
    'menu_counts',
    () => guard(() async {
      final row = (await Supabase.instance.client.rpc(
        'more_menu_counts',
        params: {'p_tenant_id': _requireTenantId()},
      )).single;
      return MoreMenuCounts(
        customers: row['customers'] as int,
        suppliers: row['suppliers'] as int,
        vehiclesActive: row['vehicles_active'] as int,
        vehiclesExternal: row['vehicles_external'] as int,
        drivers: row['drivers'] as int,
        agreements: row['agreements'] as int,
        routeRates: row['route_rates'] as int,
        staff: row['staff'] as int,
      );
    }),
  );
}
