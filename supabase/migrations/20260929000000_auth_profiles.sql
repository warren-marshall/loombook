-- Extensions the API's entities rely on (Location uses PostGIS geography,
-- TypeORM's uuid columns use uuid-ossp).
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists postgis with schema extensions;

-- public."user" is the app profile for a Supabase Auth account: same id as
-- auth.users, no credentials. The shape mirrors apps/api's User entity so
-- TypeORM's synchronize finds it already matching.
do $$ begin
  create type public.user_userrole_enum as enum ('admin', 'basic');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.user_usertype_enum as enum ('photographer');
exception when duplicate_object then null; end $$;

create table if not exists public."user" (
  "id"        uuid primary key,
  "firstName" character varying not null,
  "lastName"  character varying not null,
  "email"     character varying not null unique,
  "userRole"  public.user_userrole_enum not null default 'basic',
  "userType"  public.user_usertype_enum not null default 'photographer',
  "createdAt" timestamp without time zone not null default now()
);

-- Profile rows are owned by these triggers, not by the API. Role comes from
-- app_metadata (only settable server-side); names from user_metadata.
create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public."user" ("id", "firstName", "lastName", "email", "userRole")
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'firstName', ''),
    coalesce(new.raw_user_meta_data ->> 'lastName', ''),
    new.email,
    coalesce(new.raw_app_meta_data ->> 'role', 'basic')::public.user_userrole_enum
  );
  return new;
end;
$$;

create or replace function public.handle_auth_user_updated()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public."user"
  set "firstName" = coalesce(new.raw_user_meta_data ->> 'firstName', "firstName"),
      "lastName"  = coalesce(new.raw_user_meta_data ->> 'lastName', "lastName"),
      "email"     = new.email,
      "userRole"  = coalesce(new.raw_app_meta_data ->> 'role', "userRole"::text)::public.user_userrole_enum
  where "id" = new.id;
  return new;
end;
$$;

create or replace function public.handle_auth_user_deleted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public."user" where "id" = old.id;
  return old;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_auth_user_created();

drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
  after update on auth.users
  for each row execute function public.handle_auth_user_updated();

drop trigger if exists on_auth_user_deleted on auth.users;
create trigger on_auth_user_deleted
  after delete on auth.users
  for each row execute function public.handle_auth_user_deleted();

-- All data access goes through the NestJS API (direct Postgres connection),
-- so keep the tables closed to PostgREST's anon/authenticated roles.
alter table public."user" enable row level security;
