import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/cache/cache_entry.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/core/supabase/supabase_guard.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/work/data/work_order_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkRepository with RepositoryCacheMixin {
  WorkRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};

  String _requireTenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  Future<List<WorkOrder>> _readAll(String tenantId) async =>
      (await Supabase.instance.client
              .from('work_orders')
              .select(
                '*, work_order_allocations(*), work_order_charge_lines(*)',
              )
              .eq('tenant_id', tenantId)
              .order('date', ascending: false))
          .map(WorkOrderRow.fromRow)
          .toList();

  Future<WorkOrder> _read(String tenantId, String id) async =>
      WorkOrderRow.fromRow(
        await Supabase.instance.client
            .from('work_orders')
            .select('*, work_order_allocations(*), work_order_charge_lines(*)')
            .eq('tenant_id', tenantId)
            .eq('id', id)
            .single(),
      );

  Future<Result<List<WorkOrder>>> fetchAll() => cached(
    _cache,
    'all',
    () => guard(() async => _readAll(_requireTenantId())),
  );

  Future<Result<PaginatedResult<WorkOrder>>> fetchPage({
    required int pageNumber,
    int pageSize = 50,
    WorkStatus? status,
    String? search,
  }) => cached(
    _cache,
    'page_${pageNumber}_${pageSize}_${status?.toJson() ?? 'all'}_${search ?? ''}',
    () => guard(() async {
      final tenantId = _requireTenantId();
      var query = Supabase.instance.client
          .from('work_orders')
          .select('*, work_order_allocations(*), work_order_charge_lines(*)')
          .eq('tenant_id', tenantId);
      if (status != null) query = query.eq('status', status.toJson());
      if (search?.isNotEmpty == true) {
        query = query.ilike('number', '%$search%');
      }
      final response = await query
          .order('date', ascending: false)
          .range((pageNumber - 1) * pageSize, pageNumber * pageSize - 1)
          .count(CountOption.exact);
      return PaginatedResult(
        items: response.data.map(WorkOrderRow.fromRow).toList(),
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalRecords: response.count,
      );
    }),
  );

  Future<Result<WorkOrder>> fetchOne(String id) =>
      guard(() async => _read(_requireTenantId(), id));

  Future<Result<WorkOrder>> create(WorkOrder workOrder) => guard(() async {
    final tenantId = _requireTenantId();
    final id = await Supabase.instance.client.rpc<String>(
      'create_work_order',
      params: {'payload': workOrder.toRow(tenantId)},
    );
    clearCache(_cache);
    return _read(tenantId, id);
  });

  Future<Result<WorkOrder>> complete(String id) => guard(() async {
    final tenantId = _requireTenantId();
    await Supabase.instance.client.rpc<void>(
      'complete_work_order',
      params: {'p_id': id},
    );
    clearCache(_cache);
    return _read(tenantId, id);
  });

  Future<Result<WorkOrder>> cancel(String id) => guard(() async {
    final tenantId = _requireTenantId();
    await Supabase.instance.client.rpc<void>(
      'cancel_work_order',
      params: {'p_id': id},
    );
    clearCache(_cache);
    return _read(tenantId, id);
  });

  Future<Result<WorkOrder>> duplicate(String id) async {
    final sourceResult = await fetchOne(id);
    return switch (sourceResult) {
      Failure(:final failure) => Failure(failure),
      Success(:final value) => create(
        WorkOrder(
          id: '',
          number: '',
          customerId: value.customerId,
          agreementId: value.agreementId,
          date: value.date,
          pickup: value.pickup,
          destination: value.destination,
          workType: value.workType,
          plannedStart: value.plannedStart,
          plannedEnd: value.plannedEnd,
          customerJobReference: value.customerJobReference,
          description: value.description,
          status: WorkStatus.planned,
          allocations: List.of(value.allocations),
          chargeLines: List.of(value.chargeLines),
          notes: value.notes,
        ),
      ),
    };
  }

  void invalidateCache() => clearCache(_cache);
}
