import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/cache/cache_entry.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/core/supabase/supabase_guard.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_extension.dart';
import 'package:cuboid_flutter_template/features/more/data/more_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgreementRepository with RepositoryCacheMixin {
  AgreementRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};

  String _requireTenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  void invalidateCache() => clearCache(_cache);

  Future<Result<List<Agreement>>> fetchAgreements() => cached(
    _cache,
    'all',
    () => guard(() async {
      final tenantId = _requireTenantId();
      return (await Supabase.instance.client
              .from('agreements')
              .select()
              .eq('tenant_id', tenantId)
              .eq('is_archived', false)
              .order('name'))
          .map(AgreementRow.fromRow)
          .toList();
    }),
  );

  Future<Result<PaginatedResult<Agreement>>> fetchAgreementsPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
    String? customerId,
    RateModel? rateModel,
  }) {
    final key =
        'page_${pageNumber}_${pageSize}_${search ?? ''}_${customerId ?? ''}_${rateModel?.toJson() ?? ''}';
    return cached(
      _cache,
      key,
      () => guard(() async {
        final tenantId = _requireTenantId();
        var query = Supabase.instance.client
            .from('agreements')
            .select()
            .eq('tenant_id', tenantId)
            .eq('is_archived', false);
        if (search != null && search.isNotEmpty) {
          query = query.ilike('name', '%$search%');
        }
        if (customerId != null) query = query.eq('customer_id', customerId);
        if (rateModel != null) {
          query = query.eq('rate_model', rateModel.toJson());
        }
        final response = await query
            .order('name')
            .range((pageNumber - 1) * pageSize, pageNumber * pageSize - 1)
            .count(CountOption.exact);
        return PaginatedResult(
          items: response.data.map(AgreementRow.fromRow).toList(),
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalRecords: response.count,
        );
      }),
    );
  }

  Future<Result<Agreement>> addAgreement(Agreement agreement) async {
    final result = await guard(() async {
      final tenantId = _requireTenantId();
      final row = agreement.toRow(tenantId);
      final saved = agreement.id.isEmpty
          ? await Supabase.instance.client
                .from('agreements')
                .insert(row)
                .select()
                .single()
          : await Supabase.instance.client
                .from('agreements')
                .update(row)
                .eq('id', agreement.id)
                .select()
                .single();
      return AgreementRow.fromRow(saved);
    });
    if (result case Success()) _onMutated();
    return result;
  }

  Future<Result<void>> archiveAgreement(String id) async {
    final result = await guard(() async {
      _requireTenantId();
      await Supabase.instance.client
          .from('agreements')
          .update({'is_archived': true})
          .eq('id', id);
    });
    if (result case Success()) _onMutated();
    return result;
  }

  /// Agreement counts feed into MoreRepository's menu badge, so a mutation
  /// here has to invalidate that cache too, not just this one.
  void _onMutated() {
    invalidateCache();
    locator<MoreRepository>().invalidateCache();
  }
}
