import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/cache/cache_entry.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/core/supabase/supabase_guard.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/more_repository.dart';
import 'package:fleetgo/features/more/data/route_rate_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteRateRepository with RepositoryCacheMixin {
  RouteRateRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};

  String _requireTenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  void invalidateCache() => clearCache(_cache);

  Future<Result<List<RouteRate>>> fetchRouteRates() => cached(
    _cache,
    'all',
    () => guard(() async {
      final tenantId = _requireTenantId();
      return (await Supabase.instance.client
              .from('route_rates')
              .select()
              .eq('tenant_id', tenantId)
              .eq('is_archived', false)
              .order('pickup'))
          .map(RouteRateRow.fromRow)
          .toList();
    }),
  );

  Future<Result<PaginatedResult<RouteRate>>> fetchRouteRatesPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) {
    final key = 'page_${pageNumber}_${pageSize}_${search ?? ''}';
    return cached(
      _cache,
      key,
      () => guard(() async {
        final tenantId = _requireTenantId();
        var query = Supabase.instance.client
            .from('route_rates')
            .select()
            .eq('tenant_id', tenantId)
            .eq('is_archived', false);
        if (search != null && search.isNotEmpty) {
          query = query.ilike('pickup', '%$search%');
        }
        final response = await query
            .order('pickup')
            .range((pageNumber - 1) * pageSize, pageNumber * pageSize - 1)
            .count(CountOption.exact);
        return PaginatedResult(
          items: response.data.map(RouteRateRow.fromRow).toList(),
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalRecords: response.count,
        );
      }),
    );
  }

  Future<Result<RouteRate>> addRouteRate(RouteRate rate) async {
    final result = await guard(() async {
      final tenantId = _requireTenantId();
      final row = rate.toRow(tenantId);
      final saved = rate.id.isEmpty
          ? await Supabase.instance.client
                .from('route_rates')
                .insert(row)
                .select()
                .single()
          : await Supabase.instance.client
                .from('route_rates')
                .update(row)
                .eq('id', rate.id)
                .select()
                .single();
      return RouteRateRow.fromRow(saved);
    });
    if (result case Success()) _onMutated();
    return result;
  }

  Future<Result<void>> archiveRouteRate(String id) async {
    final result = await guard(() async {
      _requireTenantId();
      await Supabase.instance.client
          .from('route_rates')
          .update({'is_archived': true})
          .eq('id', id);
    });
    if (result case Success()) _onMutated();
    return result;
  }

  /// Route rate counts feed into MoreRepository's menu badge, so a mutation
  /// here has to invalidate that cache too, not just this one.
  void _onMutated() {
    invalidateCache();
    locator<MoreRepository>().invalidateCache();
  }
}
