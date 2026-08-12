BEGIN;
SELECT plan(20);

INSERT INTO auth.users (id, aud, role, email)
VALUES
  (
    '22222222-2222-4222-8222-222222222222',
    'authenticated',
    'authenticated',
    'work-other@example.local'
  ),
  (
    '33333333-3333-4333-8333-333333333333',
    'authenticated',
    'authenticated',
    'work-staff@example.local'
  );

INSERT INTO public.tenants (id, name)
VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Work Other Tenant');

INSERT INTO public.tenant_members (
  id, tenant_id, user_id, display_name, email, role, status
)
VALUES
  (
    'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    '22222222-2222-4222-8222-222222222222',
    'Work Other Owner',
    'work-other@example.local',
    'owner',
    'active'
  ),
  (
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '33333333-3333-4333-8333-333333333333',
    'Work Staff',
    'work-staff@example.local',
    'staff',
    'active'
  );

INSERT INTO public.parties (id, tenant_id, name, type)
VALUES
  (
    'a1111111-1111-4111-8111-111111111111',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'Work Customer',
    'customer'
  ),
  (
    'b1111111-1111-4111-8111-111111111111',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'Other Work Customer',
    'customer'
  );

INSERT INTO public.agreements (
  id, tenant_id, reference, name, customer_id, rate_model
)
VALUES
  (
    'a2222222-2222-4222-8222-222222222222',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'WORK-AGR',
    'Work Agreement',
    'a1111111-1111-4111-8111-111111111111',
    'per_trip'
  ),
  (
    'b2222222-2222-4222-8222-222222222222',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'WORK-AGR',
    'Other Work Agreement',
    'b1111111-1111-4111-8111-111111111111',
    'per_trip'
  );

INSERT INTO public.vehicles (
  id, tenant_id, plate_number, label, vehicle_class, ownership
)
VALUES
  (
    'a3333333-3333-4333-8333-333333333333',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'WORK-001',
    'Work Vehicle',
    'three_ton',
    'owned'
  ),
  (
    'b3333333-3333-4333-8333-333333333333',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'OTHER-001',
    'Other Work Vehicle',
    'three_ton',
    'owned'
  );

INSERT INTO public.work_orders (
  id, tenant_id, number, customer_id, agreement_id, date,
  work_type, pickup, destination
)
VALUES
  (
    'a4444444-4444-4444-8444-444444444444',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'OWNER-1',
    'a1111111-1111-4111-8111-111111111111',
    'a2222222-2222-4222-8222-222222222222',
    '2026-07-17',
    'per_trip',
    'Owner Pickup',
    'Owner Destination'
  ),
  (
    'b4444444-4444-4444-8444-444444444444',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'OTHER-1',
    'b1111111-1111-4111-8111-111111111111',
    'b2222222-2222-4222-8222-222222222222',
    '2026-07-17',
    'per_trip',
    'Other Pickup',
    'Other Destination'
  );

INSERT INTO public.work_order_allocations (
  id, tenant_id, work_order_id, vehicle_id, source
)
VALUES
  (
    'a5555555-5555-4555-8555-555555555555',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'a4444444-4444-4444-8444-444444444444',
    'a3333333-3333-4333-8333-333333333333',
    'owned'
  ),
  (
    'b5555555-5555-4555-8555-555555555555',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'b4444444-4444-4444-8444-444444444444',
    'b3333333-3333-4333-8333-333333333333',
    'owned'
  );

INSERT INTO public.work_order_charge_lines (
  id, tenant_id, work_order_id, name, unit_price
)
VALUES
  (
    'a6666666-6666-4666-8666-666666666666',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'a4444444-4444-4444-8444-444444444444',
    'Owner charge',
    100
  ),
  (
    'b6666666-6666-4666-8666-666666666666',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'b4444444-4444-4444-8444-444444444444',
    'Other charge',
    100
  );

CREATE TEMP TABLE work_order_test_ids (kind text primary key, id uuid);
GRANT ALL ON work_order_test_ids TO authenticated;

SELECT has_table('public', 'document_sequences', 'document sequences exists');
SELECT has_table('public', 'work_orders', 'work orders exists');
SELECT has_table(
  'public',
  'work_order_allocations',
  'work order allocations exists'
);
SELECT has_table(
  'public',
  'work_order_charge_lines',
  'work order charge lines exists'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
SET LOCAL ROLE authenticated;

SELECT results_eq(
  $$SELECT number FROM public.work_orders ORDER BY number$$,
  $$VALUES ('OWNER-1'::text)$$,
  'An owner sees only work orders in the owner tenant'
);

SELECT results_eq(
  $$SELECT count(*) FROM public.work_order_allocations$$,
  $$VALUES (1::bigint)$$,
  'An owner sees only allocations in the owner tenant'
);

SELECT results_eq(
  $$SELECT count(*) FROM public.work_order_charge_lines$$,
  $$VALUES (1::bigint)$$,
  'An owner sees only charge lines in the owner tenant'
);

SELECT lives_ok(
  $$DELETE FROM public.work_orders
    WHERE id = 'a4444444-4444-4444-8444-444444444444'$$,
  'A planned work order can be deleted'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);

SELECT throws_ok(
  $$INSERT INTO public.work_orders (
      tenant_id, number, customer_id, agreement_id, date,
      work_type, pickup, destination
    ) VALUES (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'STAFF-1',
      'a1111111-1111-4111-8111-111111111111',
      'a2222222-2222-4222-8222-222222222222',
      '2026-07-17', 'per_trip', 'Staff Pickup', 'Staff Destination'
    )$$,
  '42501',
  NULL,
  'Clients cannot insert work orders directly'
);

SELECT throws_ok(
  $$SELECT public.create_work_order(
      jsonb_build_object(
        'tenant_id', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'customer_id', 'a1111111-1111-4111-8111-111111111111',
        'agreement_id', 'a2222222-2222-4222-8222-222222222222',
        'date', '2026-07-17', 'work_type', 'per_trip',
        'pickup', 'Pickup', 'destination', 'Destination'
      )
    )$$,
  '42501',
  NULL,
  'A staff member without operations access cannot create work'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);

INSERT INTO work_order_test_ids (kind, id)
SELECT 'no_allocation', public.create_work_order(
  jsonb_build_object(
    'tenant_id', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'customer_id', 'a1111111-1111-4111-8111-111111111111',
    'agreement_id', 'a2222222-2222-4222-8222-222222222222',
    'date', '2026-07-17',
    'work_type', 'per_trip',
    'pickup', 'Pickup',
    'destination', 'Destination',
    'allocations', '[]'::jsonb,
    'charge_lines', jsonb_build_array(
      jsonb_build_object('name', 'Transport', 'unit_price', 100)
    )
  )
);

SELECT throws_ok(
  $$SELECT public.complete_work_order(
      (SELECT id FROM work_order_test_ids WHERE kind = 'no_allocation')
    )$$,
  'P0001',
  NULL,
  'Completion rejects work without a vehicle allocation'
);

INSERT INTO work_order_test_ids (kind, id)
SELECT 'complete', public.create_work_order(
  jsonb_build_object(
    'tenant_id', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'customer_id', 'a1111111-1111-4111-8111-111111111111',
    'agreement_id', 'a2222222-2222-4222-8222-222222222222',
    'date', '2026-07-17',
    'work_type', 'per_trip',
    'pickup', 'Pickup',
    'destination', 'Destination',
    'allocations', jsonb_build_array(
      jsonb_build_object(
        'vehicle_id', 'a3333333-3333-4333-8333-333333333333',
        'source', 'owned'
      )
    ),
    'charge_lines', '[]'::jsonb
  )
);

SELECT lives_ok(
  $$SELECT public.complete_work_order(
      (SELECT id FROM work_order_test_ids WHERE kind = 'complete')
    )$$,
  'A planned work order with an allocation completes'
);

DELETE FROM public.work_orders
WHERE id = (SELECT id FROM work_order_test_ids WHERE kind = 'complete');

SELECT results_eq(
  $$SELECT count(*) FROM public.work_orders
    WHERE id = (SELECT id FROM work_order_test_ids WHERE kind = 'complete')$$,
  $$VALUES (1::bigint)$$,
  'A completed work order cannot be deleted'
);

SELECT results_eq(
  $$SELECT status FROM public.work_orders
    WHERE id = (SELECT id FROM work_order_test_ids WHERE kind = 'complete')$$,
  $$VALUES ('completed'::text)$$,
  'Completed work stores the completed status'
);

INSERT INTO work_order_test_ids (kind, id)
SELECT 'cancel', public.create_work_order(
  jsonb_build_object(
    'tenant_id', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'customer_id', 'a1111111-1111-4111-8111-111111111111',
    'agreement_id', 'a2222222-2222-4222-8222-222222222222',
    'date', '2026-07-17',
    'work_type', 'per_trip',
    'pickup', 'Pickup',
    'destination', 'Destination',
    'allocations', '[]'::jsonb,
    'charge_lines', '[]'::jsonb
  )
);

SELECT lives_ok(
  $$SELECT public.cancel_work_order(
      (SELECT id FROM work_order_test_ids WHERE kind = 'cancel')
    )$$,
  'A planned work order can be canceled'
);

SELECT throws_ok(
  $$SELECT public.cancel_work_order(
      (SELECT id FROM work_order_test_ids WHERE kind = 'cancel')
    )$$,
  'P0001',
  NULL,
  'A canceled work order cannot be canceled again'
);

SELECT throws_ok(
  $$UPDATE public.work_orders SET status = 'billed'
    WHERE id = (SELECT id FROM work_order_test_ids WHERE kind = 'complete')$$,
  '42501',
  NULL,
  'Work order status cannot be forged by direct update'
);

SELECT throws_ok(
  $$SELECT public.create_work_order(
      jsonb_build_object(
        'tenant_id', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'customer_id', 'b1111111-1111-4111-8111-111111111111',
        'agreement_id', 'a2222222-2222-4222-8222-222222222222',
        'date', '2026-07-17', 'work_type', 'per_trip',
        'pickup', 'Pickup', 'destination', 'Destination'
      )
    )$$,
  '23503',
  NULL,
  'Work cannot reference another tenant''s customer'
);

SELECT results_eq(
  $$SELECT count(*) FROM public.work_orders
    WHERE tenant_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      AND number ~ '^WO-\d{4}-\d{3,}$'$$,
  $$VALUES (3::bigint)$$,
  'Document numbers use the PREFIX-YEAR-NNN format without reuse'
);

RESET ROLE;

SELECT results_eq(
  $$SELECT next_value FROM public.document_sequences
    WHERE tenant_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      AND kind = 'work_order'
      AND year = extract(year from now())::integer$$,
  $$VALUES (4::bigint)$$,
  'The next sequence value advances after each work order'
);

SELECT * FROM finish();
ROLLBACK;
