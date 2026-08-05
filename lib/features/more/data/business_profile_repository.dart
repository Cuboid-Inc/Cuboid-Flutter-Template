import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/cache/cache_entry.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/core/supabase/supabase_guard.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessProfileRepository with RepositoryCacheMixin {
  BusinessProfileRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};

  String _requireTenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  void invalidateCache() => clearCache(_cache);

  Future<Result<BusinessProfile>> fetchBusinessProfile() => cached(
    _cache,
    'business_profile',
    () => guard(() async {
      final tenantId = _requireTenantId();
      final row = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('tenant_id', tenantId)
          .maybeSingle();
      return row == null
          ? const BusinessProfile(legalName: '')
          : BusinessProfileRow.fromRow(row);
    }),
  );

  Future<Result<BusinessProfile>> updateBusinessProfile(
    BusinessProfile profile,
  ) async {
    final result = await guard(() async {
      final tenantId = _requireTenantId();
      final saved = await Supabase.instance.client
          .from('business_profiles')
          .upsert(profile.toRow(tenantId), onConflict: 'tenant_id')
          .select()
          .single();
      return BusinessProfileRow.fromRow(saved);
    });
    if (result case Success()) invalidateCache();
    return result;
  }
}
