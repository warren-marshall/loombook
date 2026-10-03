-- Local dev data, applied by `supabase db reset`.
-- Dev login: dev@loombook.dev / Password123!  (admin)

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone_change, phone_change_token, reauthentication_token
) values (
  '00000000-0000-0000-0000-000000000000',
  '11111111-0000-4000-8000-000000000001',
  'authenticated', 'authenticated', 'dev@loombook.dev',
  extensions.crypt('Password123!', extensions.gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"],"role":"admin"}',
  '{"first_name":"Dev","last_name":"Admin","email_verified":true}',
  now(), now(), '', '', '', '', '', '', '', ''
);

insert into auth.identities (
  id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
  gen_random_uuid(), '11111111-0000-4000-8000-000000000001',
  '11111111-0000-4000-8000-000000000001',
  '{"sub":"11111111-0000-4000-8000-000000000001","email":"dev@loombook.dev","email_verified":true}',
  'email', now(), now(), now()
);
