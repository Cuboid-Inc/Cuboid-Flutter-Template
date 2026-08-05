import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/cache/cache_entry.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/core/supabase/supabase_guard.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/parties/data/party_balance_extension.dart';
import 'package:fleetgo/features/parties/data/party_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartiesRepository with RepositoryCacheMixin {
  PartiesRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};

  String _requireTenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  Future<Result<List<Party>>> fetchAll() => cached(
    _cache,
    'all',
    () => guard(() async {
      final tenantId = _requireTenantId();
      return (await Supabase.instance.client
              .from('parties')
              .select()
              .eq('tenant_id', tenantId)
              .eq('is_archived', false)
              .order('name'))
          .map(PartyRow.fromRow)
          .toList();
    }),
  );

  Future<Result<List<Party>>> partiesForDirection(PaymentDirection direction) =>
      cached(
        _cache,
        'direction_${direction.name}',
        () => guard(() async {
          final tenantId = _requireTenantId();
          final type = direction == PaymentDirection.incoming
              ? PartyType.customer
              : PartyType.supplier;
          return (await Supabase.instance.client
                  .from('parties')
                  .select()
                  .eq('tenant_id', tenantId)
                  .eq('is_archived', false)
                  .eq('type', type.toJson())
                  .order('name'))
              .map(PartyRow.fromRow)
              .toList();
        }),
      );

  Future<Result<PaginatedResult<Party>>> fetchPage({
    required int pageNumber,
    int pageSize = 50,
    PartyType? type,
    String? search,
  }) => cached(
    _cache,
    'page_${pageNumber}_${pageSize}_${type?.toJson() ?? 'all'}_${search ?? ''}',
    () => guard(() async {
      final tenantId = _requireTenantId();
      final from = (pageNumber - 1) * pageSize;
      var query = Supabase.instance.client
          .from('parties')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_archived', false);
      if (type != null) query = query.eq('type', type.toJson());
      if (search?.isNotEmpty == true) query = query.ilike('name', '%$search%');
      final response = await query
          .order('name')
          .range(from, from + pageSize - 1)
          .count(CountOption.exact);
      return PaginatedResult(
        items: response.data.map(PartyRow.fromRow).toList(),
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalRecords: response.count,
      );
    }),
  );

  Future<Result<Party>> fetchById(String id) => cached(
    _cache,
    'by_id_$id',
    () => guard(() async {
      final tenantId = _requireTenantId();
      final row = await Supabase.instance.client
          .from('parties')
          .select()
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .single();
      return PartyRow.fromRow(row);
    }),
  );

  Future<Result<Party>> create(Party party) => guard(() async {
    final tenantId = _requireTenantId();
    final row = party.toRow(tenantId);
    final saved = party.id.isEmpty
        ? await Supabase.instance.client
              .from('parties')
              .insert(row)
              .select()
              .single()
        : await Supabase.instance.client
              .from('parties')
              .update(row)
              .eq('id', party.id)
              .select()
              .single();
    clearCache(_cache);
    return PartyRow.fromRow(saved);
  });

  Future<Result<void>> archive(String id) => guard(() async {
    await Supabase.instance.client
        .from('parties')
        .update({'is_archived': true})
        .eq('id', id);
    clearCache(_cache);
  });

  void invalidateCache() => clearCache(_cache);

  Future<Result<List<PartyBalance>>> fetchBalances() => cached(
    _cache,
    'balances',
    () => guard(() async {
      final tenantId = _requireTenantId();
      final rows = await Supabase.instance.client
          .from('party_balances')
          .select('party_id, balance')
          .eq('tenant_id', tenantId);
      return rows.map(PartyBalanceRow.fromRow).toList();
    }),
  );
}
