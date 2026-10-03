# LoomBook

Next.js web app (`apps/web`) on Supabase: Postgres, Auth and row-level security. There is no separate API; the app talks to Supabase directly and the database schema lives in SQL migrations.

## Prerequisites

- Node.js and npm
- Docker Desktop running (for local Supabase)

## Setup

```bash
npm install
npm run db:start
```

`db:start` pulls the images on first run, applies `supabase/migrations`, loads `supabase/seed.sql`, and prints the local URLs and keys (Studio is at http://127.0.0.1:54323). Re-print them any time with `npx supabase status -o env`.

Create the web app's env file and fill in `API_URL` and `ANON_KEY` from that output:

```bash
cp apps/web/.env.example apps/web/.env.local
```

Then start the app:

```bash
npm run dev
```

Sign in at http://localhost:3000/admin/login with the seeded admin: `dev@loombook.dev` / `Password123!`.

> **Port conflict:** the stack uses 54321 (API), 54322 (Postgres) and 54323 (Studio). Change them in `supabase/config.toml` if they clash.

## Changing the schema

1. `npx supabase migration new <name>` creates a timestamped file in `supabase/migrations/`.
2. Write the SQL. Every table needs `enable row level security` and policies, because the browser queries the database directly and policies are the only access control.
3. `npm run db:reset` rebuilds the local database from all migrations and the seed, so you know it applies from scratch.
4. `npm run db:types` regenerates `apps/web/src/lib/database.types.ts`.

Never edit a migration once it has been applied anywhere other than your machine; add a new one.

## Auth

- Supabase Auth handles login and sessions; `apps/web/src/proxy.ts` refreshes the session cookie and protects `/admin/dashboard`.
- Public sign-up is disabled (`supabase/config.toml`). Create users in Studio (Authentication) or with the auth admin API.
- Each account gets a row in `public.profiles` via a trigger. The role (`admin` / `basic`) comes from the account's `app_metadata.role`, which users can't edit themselves. `public.is_admin()` is available for RLS policies.

## Commands

| Task | Command |
| --- | --- |
| Start / stop local Supabase | `npm run db:start` / `npm run db:stop` |
| Rebuild the DB from migrations + seed | `npm run db:reset` |
| Regenerate TypeScript types | `npm run db:types` |
| Run the web app | `npm run dev` |
| Production build | `npm run build` |
| Database shell | `docker exec -it supabase_db_loombook psql -U postgres -d postgres` |

## Deploying

Create a hosted Supabase project, then `npx supabase link --project-ref <ref>` and `npx supabase db push` to apply the migrations. Point `apps/web/.env.local` (or your host's env vars) at the project's URL and anon key.
