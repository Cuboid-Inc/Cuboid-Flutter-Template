import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/cache/cache_entry.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/core/supabase/supabase_guard.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/more_repository.dart';
import 'package:fleetgo/features/more/data/vehicle_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleRepository with RepositoryCacheMixin {
  VehicleRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};

  String _requireTenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  void invalidateCache() => clearCache(_cache);

  Future<Result<List<Vehicle>>> fetchVehicles() => cached(
    _cache,
    'all',
    () => guard(() async {
      final tenantId = _requireTenantId();
      return (await Supabase.instance.client
              .from('vehicles')
              .select()
              .eq('tenant_id', tenantId)
              .eq('is_archived', false)
              .order('label'))
          .map(VehicleRow.fromRow)
          .toList();
    }),
  );

  Future<Result<PaginatedResult<Vehicle>>> fetchVehiclesPage({
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
            .from('vehicles')
            .select()
            .eq('tenant_id', tenantId)
            .eq('is_archived', false);
        if (search != null && search.isNotEmpty) {
          query = query.ilike('label', '%$search%');
        }
        final response = await query
            .order('label')
            .range((pageNumber - 1) * pageSize, pageNumber * pageSize - 1)
            .count(CountOption.exact);
        return PaginatedResult(
          items: response.data.map(VehicleRow.fromRow).toList(),
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalRecords: response.count,
        );
      }),
    );
  }

  Future<Result<Vehicle>> fetchById(String id) => cached(
    _cache,
    'by_id_$id',
    () => guard(() async {
      final tenantId = _requireTenantId();
      final row = await Supabase.instance.client
          .from('vehicles')
          .select()
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .single();
      return VehicleRow.fromRow(row);
    }),
  );

  Future<Result<Vehicle>> addVehicle(Vehicle vehicle) async {
    final result = await guard(() async {
      final tenantId = _requireTenantId();
      final row = vehicle.toRow(tenantId);
      final saved = vehicle.id.isEmpty
          ? await Supabase.instance.client
                .from('vehicles')
                .insert(row)
                .select()
                .single()
          : await Supabase.instance.client
                .from('vehicles')
                .update(row)
                .eq('id', vehicle.id)
                .select()
                .single();
      return VehicleRow.fromRow(saved);
    });
    if (result case Success()) _onMutated();
    return result;
  }

  Future<Result<void>> archiveVehicle(String id) async {
    final result = await guard(() async {
      _requireTenantId();
      await Supabase.instance.client
          .from('vehicles')
          .update({'is_archived': true})
          .eq('id', id);
    });
    if (result case Success()) _onMutated();
    return result;
  }

  /// Vehicle counts feed into MoreRepository's menu badge, so a mutation
  /// here has to invalidate that cache too, not just this one.
  void _onMutated() {
    invalidateCache();
    locator<MoreRepository>().invalidateCache();
  }
}
