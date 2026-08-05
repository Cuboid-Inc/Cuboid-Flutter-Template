BEGIN;
SELECT plan(7);

-- Second tenant + member, reused shape from auth_rls_test.sql, needed for
-- cross-tenant isolation checks.
INSERT INTO auth.users (id, aud, role, email)
VALUES (
  '22222222-2222-4222-8222-222222222222',
  'authenticated',
  'authenticated',
  'other@fleetgo.local'
);

INSERT INTO public.tenants (id, name)
VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Other Local Tenant');

INSERT INTO public.tenant_members (
  id,
  tenant_id,
  user_id,
  display_name,
  email,
  role,
  status
)
VALUES (
  'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  '22222222-2222-4222-8222-222222222222',
  'Other Local User',
  'other@fleetgo.local',
  'owner',
  'active'
);

-- Staff member inside the seeded owner's tenant (aaaaaaaa...), no access
-- packs yet, to exercise the master_data-pack gate.
INSERT INTO auth.users (id, aud, role, email)
VALUES (
  '33333333-3333-4333-8333-333333333333',
  'authenticated',
  'authenticated',
  'staff@fleetgo.local'
);

INSERT INTO public.tenant_members (
  id,
  tenant_id,
  user_id,
  display_name,
  email,
  role,
  status
)
VALUES (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '33333333-3333-4333-8333-333333333333',
  'Local Staff',
  'staff@fleetgo.local',
  'staff',
  'active'
);

-- One party fixture per tenant, inserted as the test-runner role (bypasses
-- RLS) so the cross-tenant SELECT check below has something to isolate.
INSERT INTO public.parties (tenant_id, name, type)
VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Owner Tenant Customer', 'customer');

INSERT INTO public.parties (tenant_id, name, type)
VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Other Tenant Customer', 'customer');

SELECT has_table('public', 'parties', 'parties exists');
SELECT has_function(
  'private',
  'has_access_pack',
  ARRAY['uuid', 'text'],
  'private.has_access_pack exists'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
SET LOCAL ROLE authenticated;

SELECT results_eq(
  $$SELECT count(*) FROM public.parties$$,
  $$VALUES (1::bigint)$$,
  'An owner sees only their own tenant''s parties'
);

SELECT lives_ok(
  $$INSERT INTO public.parties (tenant_id, name, type)
    VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Owner Added Supplier', 'supplier')$$,
  'The owner can insert a party without an explicit access pack row'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);

SELECT throws_ok(
  $$INSERT INTO public.parties (tenant_id, name, type)
    VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Staff Without Pack', 'customer')$$,
  '42501',
  NULL,
  'Staff without the master_data pack cannot insert a party'
);

RESET ROLE;
INSERT INTO public.member_access_packs (member_id, pack)
VALUES ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'master_data');
SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);

SELECT lives_ok(
  $$INSERT INTO public.parties (tenant_id, name, type)
    VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Staff With Pack', 'customer')$$,
  'Staff with the master_data pack can insert a party'
);

-- RLS UPDATE policies filter matchable rows via USING rather than raising an
-- error, so a cross-tenant UPDATE silently affects zero rows instead of
-- throwing. Assert the other tenant's row is unchanged, checked as the
-- unrestricted test-runner role so the assertion itself isn't subject to RLS.
UPDATE public.parties
SET name = 'Renamed'
WHERE tenant_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

RESET ROLE;

SELECT results_eq(
  $$SELECT name FROM public.parties WHERE tenant_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'$$,
  $$VALUES ('Other Tenant Customer'::text)$$,
  'Staff with the master_data pack still cannot update another tenant''s party'
);

SELECT * FROM finish();
ROLLBACK;
