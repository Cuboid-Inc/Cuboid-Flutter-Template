BEGIN;
SELECT plan(10);

INSERT INTO auth.users (id, aud, role, email)
VALUES (
  '22222222-2222-4222-8222-222222222222',
  'authenticated',
  'authenticated',
  'other@example.local'
);

INSERT INTO public.tenants (id, name)
VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Other Local Tenant');

INSERT INTO public.tenant_members (
  id,
  tenant_id,
  user_id,
  display_name,
  email,
  status
)
VALUES (
  'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  '22222222-2222-4222-8222-222222222222',
  'Other Local User',
  'other@example.local',
  'invited'
);

INSERT INTO public.member_access_packs (member_id, pack)
VALUES ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'operations');

SELECT has_table('public', 'tenants', 'tenants exists');
SELECT has_table('public', 'user_profiles', 'user_profiles exists');
SELECT has_table('public', 'tenant_members', 'tenant_members exists');
SELECT has_table(
  'public',
  'member_access_packs',
  'member_access_packs exists'
);
SELECT has_function('public', 'accept_invitation', ARRAY[]::name[]);

SELECT set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
SET LOCAL ROLE authenticated;

SELECT results_eq(
  $$SELECT name FROM public.tenants ORDER BY name$$,
  $$VALUES ('Cuboid Local'::text)$$,
  'An owner sees only the assigned tenant'
);

SELECT results_eq(
  $$SELECT count(*) FROM public.tenant_members$$,
  $$VALUES (1::bigint)$$,
  'An owner cannot read another tenant member'
);

SELECT results_eq(
  $$SELECT count(*) FROM public.member_access_packs WHERE member_id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'$$,
  $$VALUES (0::bigint)$$,
  'An owner cannot read another tenant access pack'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);

SELECT ok(public.accept_invitation(), 'An invited member accepts access');

SELECT results_eq(
  $$SELECT status FROM public.tenant_members WHERE user_id = auth.uid()$$,
  $$VALUES ('active'::text)$$,
  'Invitation acceptance activates the member'
);

SELECT * FROM finish();
ROLLBACK;
