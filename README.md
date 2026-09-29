# Local dev setup

Step-by-step instructions to spin up the `api` and `web` apps on your machine. Every step below has been run and verified against this repo.

## Prerequisites

- Node.js (check with `node --version`)
- Docker Desktop running (for local Supabase)
- npm (ships with Node)

## 1. Install dependencies

From the repo root:

```bash
npm install
```

This installs and links dependencies for the root, `apps/web`, `apps/api`, and the shared `packages/types` workspace in one shot.

## 2. Start Supabase (local)

Postgres and Auth both run from the Supabase CLI (installed as a dev dependency) in Docker:

```bash
npm run db:start
```

The first run pulls images and applies `supabase/migrations`. It prints the local URLs and keys (Studio is at http://127.0.0.1:54323); re-print them any time with `npx supabase status -o env`. Other commands: `npm run db:stop`, and `npm run db:reset` to rebuild the database from the migrations.

> **Port conflict:** the stack uses 54321 (API), 54322 (Postgres) and 54323 (Studio). Change them in `supabase/config.toml` if they clash, then update `apps/api/.env`.

## 3. Configure the API's environment

The API reads its config from `apps/api/.env` (gitignored). Create it from the example, then fill in `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` from `npx supabase status -o env` (`API_URL` -> `SUPABASE_URL`, `ANON_KEY`, `SERVICE_ROLE_KEY`):

```bash
cp apps/api/.env.example apps/api/.env
```

The `DB_*` defaults already match local Supabase. The whole schema lives in `supabase/migrations` (TypeORM's `synchronize` is off). To change it, add a migration with `npx supabase migration new <name>`, write the SQL, update the matching entity, then `npm run db:reset` to check it applies from scratch.

To point at a hosted Supabase project instead, use its project URL, keys and database connection details for the same variables.

## 4. Create the first user

Every API route is protected by a global JWT auth guard, including `POST /user` — so there's no way to create the first account through the API itself. Run the seed script once per environment instead. It creates a Supabase Auth account (public sign-up is disabled), and a trigger creates the matching `user` profile row:

Run this from the **repo root**:

```bash
npm run seed:owner --workspace=apps/api -- admin@loombook.local changeme123 Admin Owner
```

(If your shell is already inside `apps/api`, drop `--workspace=apps/api` and just run `npm run seed:owner -- ...` — the flag only resolves from the root.)

The four arguments after `--` are `email password firstname lastname` — swap in your own values (no angle brackets; in PowerShell, `<` is a reserved operator).

This boots a throwaway Nest app context and creates the account through the real `UserService` (which calls the Supabase auth admin API). Running it again with an email that already exists fails safely rather than creating a duplicate.

## 5. Start both apps

```bash
npm run dev
```

This runs the API (`http://localhost:3003`, set by `PORT` in `apps/api/.env`) and the web app (`http://localhost:3000`) concurrently, both with hot reload. The web app's `NEXT_PUBLIC_API_URL` in `apps/web/.env.local` must match the API's port — it's already set to `http://localhost:3003`.

Individually:

```bash
npm run dev:api   # NestJS, watch mode
npm run dev:web   # Next.js, Turbopack
```

## 6. Verify it's working

```bash
curl -X POST http://localhost:3003/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@loombook.local","password":"changeme123"}'
```

Should return `{"accessToken": "..."}`. On Windows PowerShell, use `Invoke-RestMethod` instead (see the [Quick reference](#quick-reference) section below) — `curl`'s quoting breaks under PowerShell.

## Stop everything

```bash
# Ctrl+C the dev process, then:
npm run db:stop
```

---

## Known issues (as of this writing)

The API doesn't compile as one whole TypeScript project yet — several in-progress modules are excluded from the build (`apps/api/tsconfig.build.json`) and **not wired into `AppModule`** because they depend on code that doesn't exist yet:

| Module | Missing dependency |
| --- | --- |
| `client` | `email-messages`, `invoice` entities |
| `contact` | (compiles once excluded modules are back) |
| `lead` | `email-messages`, `contract`, `attachment` entities; `gmail` service |
| `projects` | depends on `lead` |
| `tasks` | depends on the above |

`user` and `auth` are wired to Supabase Auth: the API's `/auth/login`, `/auth/refresh` and `/auth/logout` endpoints proxy to Supabase, the guard verifies Supabase JWTs, and the role comes from the account's `app_metadata.role`.

`api-key`/service-token auth (the `x-service-token` header path in `JwtAuthGuard`) is a stub that always rejects — `apps/api/src/api-key/api-key.service.ts` has no real key store yet. Build that out before relying on service-to-service auth.

To bring a module back once its dependencies exist: remove it from the `exclude` list in `apps/api/tsconfig.build.json`, and add it back to the `imports` array in `apps/api/src/app.module.ts`.

## Quick reference

| Task | Command |
| --- | --- |
| Start Supabase | `npm run db:start` |
| Rebuild the DB from migrations | `npm run db:reset` |
| Load dev fake data (users: `Password123!`) | `npm run seed:dev --workspace=apps/api` |
| Start both apps | `npm run dev` |
| Start API only | `npm run dev:api` |
| Start web only | `npm run dev:web` |
| Seed the first admin user | `npm run seed:owner --workspace=apps/api -- email password firstname lastname` |
| Stop Supabase | `npm run db:stop` |
| Open a database shell | `docker exec -it supabase_db_loombook psql -U postgres -d postgres -P pager=off` |

### Testing API endpoints (PowerShell)

```powershell
Invoke-RestMethod -Uri "http://localhost:3003/auth/login" -Method Post `
  -ContentType "application/json" -Body (@{ email = "admin@loombook.local"; password = "changeme123" } | ConvertTo-Json)
```
