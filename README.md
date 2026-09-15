# Local dev setup

Step-by-step instructions to spin up the `api` and `web` apps on your machine. Every step below has been run and verified against this repo.

## Prerequisites

- Node.js (check with `node --version`)
- Docker Desktop running (for Postgres)
- npm (ships with Node)

## 1. Install dependencies

From the repo root:

```bash
npm install
```

This installs and links dependencies for the root, `apps/web`, `apps/api`, and the shared `packages/types` workspace in one shot.

## 2. Start Postgres

```bash
docker compose up -d db
docker compose ps   # confirm it's "running"
```

> **Port conflict:** if you have another local project also mapping Postgres to `5432`, `docker compose up -d db` will fail with `port is already allocated`. Stop the other container (`docker stop <name>`) or change the `ports:` mapping in [docker-compose.yml](docker-compose.yml), then update `DB_PORT` in `apps/api/.env` to match.

## 3. Configure the API's environment

The API reads DB credentials and JWT secrets from `apps/api/.env` (gitignored). Create it from the example:

```bash
cp apps/api/.env.example apps/api/.env
```

The defaults match `docker-compose.yml`, so no edits are needed for local dev. `synchronize: true` is enabled in development, so TypeORM creates/updates tables automatically on boot — no manual migrations needed while iterating.

## 4. Create the first user

Every API route is protected by a global JWT auth guard, including `POST /user` — so there's no way to create the first account through the API itself. Run the seed script once per environment instead:

Run this from the **repo root**:

```bash
npm run seed:owner --workspace=apps/api -- admin@loombook.local changeme123 Admin Owner
```

(If your shell is already inside `apps/api`, drop `--workspace=apps/api` and just run `npm run seed:owner -- ...` — the flag only resolves from the root.)

The four arguments after `--` are `email password firstname lastname` — swap in your own values (no angle brackets; in PowerShell, `<` is a reserved operator).

This boots a throwaway Nest app context and creates the account through the real `UserService` (so it's hashed/validated the same way a normal signup would be). Running it again with an email that already exists fails safely rather than creating a duplicate.

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
docker compose down
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

`user` and `auth` are fully wired and working (TypeORM, JWT login/refresh/logout, bcrypt password hashing, role guard, seed script).

`api-key`/service-token auth (the `x-service-token` header path in `JwtAuthGuard`) is a stub that always rejects — `apps/api/src/api-key/api-key.service.ts` has no real key store yet. Build that out before relying on service-to-service auth.

To bring a module back once its dependencies exist: remove it from the `exclude` list in `apps/api/tsconfig.build.json`, and add it back to the `imports` array in `apps/api/src/app.module.ts`.

## Quick reference

| Task | Command |
| --- | --- |
| Start Postgres only | `docker compose up -d db` |
| Start both apps | `npm run dev` |
| Start API only | `npm run dev:api` |
| Start web only | `npm run dev:web` |
| Seed the first admin user | `npm run seed:owner --workspace=apps/api -- email password firstname lastname` |
| Stop Docker containers | `docker compose down` |
| Open a database shell | `docker exec -it loombook-db-1 psql -U postgres -d loombook -P pager=off` |

### Testing API endpoints (PowerShell)

```powershell
Invoke-RestMethod -Uri "http://localhost:3003/auth/login" -Method Post `
  -ContentType "application/json" -Body (@{ email = "admin@loombook.local"; password = "changeme123" } | ConvertTo-Json)
```
