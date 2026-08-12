BEGIN;
SELECT plan(8);

INSERT INTO auth.users (id, aud, role, email)
VALUES
  (
    '44444444-4444-4444-8444-444444444444',
    'authenticated',
    'authenticated',
    'master-other@example.local'
  ),
  (
    '55555555-5555-4555-8555-555555555555',
    'authenticated',
    'authenticated',
    'master-staff@example.local'
  ),
  (
    '66666666-6666-4666-8666-666666666666',
    'authenticated',
    'authenticated',
    'master-manager@example.local'
  );

INSERT INTO public.tenants (id, name)
VALUES ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'Master Data Other Tenant');

INSERT INTO public.tenant_members (
  id,
  tenant_id,
  user_id,
  display_name,
  email,
  role,
  status
)
VALUES
  (
    '77777777-7777-4777-8777-777777777777',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    '44444444-4444-4444-8444-444444444444',
    'Master Data Other User',
    'master-other@example.local',
    'owner',
    'active'
  ),
  (
    '88888888-8888-4888-8888-888888888888',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '55555555-5555-4555-8555-555555555555',
    'Master Data Staff',
    'master-staff@example.local',
    'staff',
    'active'
  ),
  (
    '99999999-9999-4999-8999-999999999999',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '66666666-6666-4666-8666-666666666666',
    'Master Data Manager',
    'master-manager@example.local',
    'staff',
    'active'
  );

INSERT INTO public.member_access_packs (member_id, pack)
VALUES
  ('99999999-9999-4999-8999-999999999999', 'operations'),
  ('99999999-9999-4999-8999-999999999999', 'master_data'),
  ('99999999-9999-4999-8999-999999999999', 'money'),
  ('99999999-9999-4999-8999-999999999999', 'reports');

INSERT INTO public.vehicles (tenant_id, plate_number, label, vehicle_class, ownership)
VALUES
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'MASTER-OWNER-001',
    'Owner Tenant Vehicle',
    'three_ton',
    'owned'
  ),
  (
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    'MASTER-OTHER-001',
    'Other Tenant Vehicle',
    'three_ton',
    'owned'
  );

SELECT has_table('public', 'vehicles', 'vehicles exists');
SELECT has_table('public', 'drivers', 'drivers exists');
SELECT has_table('public', 'agreements', 'agreements exists');
SELECT has_table('public', 'route_rates', 'route_rates exists');
SELECT has_table('public', 'business_profiles', 'business_profiles exists');

SELECT set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
SET LOCAL ROLE authenticated;

SELECT results_eq(
  $$SELECT plate_number FROM public.vehicles ORDER BY plate_number$$,
  $$VALUES ('MASTER-OWNER-001'::text)$$,
  'An owner sees only the owner tenant vehicle'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '55555555-5555-4555-8555-555555555555',
  true
);

SELECT throws_ok(
  $$INSERT INTO public.vehicles (
      tenant_id, plate_number, label, vehicle_class, ownership
    ) VALUES (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'MASTER-STAFF-001',
      'Staff Vehicle',
      'pickup',
      'owned'
    )$$,
  '42501',
  NULL,
  'Staff without the master_data pack cannot insert a vehicle'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '66666666-6666-4666-8666-666666666666',
  true
);

SELECT throws_ok(
  $$INSERT INTO public.business_profiles (tenant_id, legal_name)
    VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Non-owner Business')$$,
  '42501',
  NULL,
  'A non-owner cannot insert a business profile despite all access packs'
);

SELECT * FROM finish();
ROLLBACK;
