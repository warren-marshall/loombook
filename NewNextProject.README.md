## Stack & structure

This project follows an **npm-workspaces monorepo** pattern, the same shape used across projects like `warren-marshall-consulting`:

```
loombook/
├── apps/
│   ├── web/          # Next.js frontend (App Router, TypeScript)
│   └── api/           # NestJS backend
├── packages/
│   └── types/          # Shared TypeScript types, imported by both apps
├── docker-compose.yml   # Postgres for local dev
└── package.json         # Workspace root — wires everything together
```

`apps/*` and `packages/*` are npm workspaces (declared under `"workspaces"` in the root `package.json`), so a single `npm install` at the repo root installs and links dependencies for everything, including the internal `@loombook/types` package.

---

## Playbook: bootstrapping a new project from scratch

This is the repeatable recipe for setting this project up (or any future one built the same way). Swap `<project-name>` for the real name throughout.

### 0. Prerequisites

- Node.js (check with `node --version`)
- Docker Desktop running (for Postgres)
- npm (ships with Node)

### 1. Create the repo and the workspace root

```bash
mkdir <project-name> && cd <project-name>
git init
mkdir -p apps packages
```

Create the root `package.json`:

```json
{
  "name": "<project-name>",
  "private": true,
  "version": "1.0.0",
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "dev": "concurrently -n API,WEB -c blue,magenta \"npm run start:dev --workspace=apps/api\" \"npm run dev --workspace=apps/web\"",
    "dev:api": "npm run start:dev --workspace=apps/api",
    "dev:web": "npm run dev --workspace=apps/web",
    "build": "npm run build --workspace=apps/api && npm run build --workspace=apps/web",
    "test": "npm run test --workspace=apps/api"
  },
  "devDependencies": {
    "concurrently": "^10.0.3"
  }
}
```

### 2. Scaffold the frontend (`apps/web`)

```bash
npx create-next-app@latest apps/web \
  --typescript --eslint --app --src-dir \
  --import-alias "@/*" --no-tailwind --use-npm \
  --skip-install --no-turbopack
```

`--skip-install` matters — dependencies get installed once, from the repo root, after everything is wired into the workspace.

### 3. Scaffold the backend (`apps/api`)

```bash
cd apps
npx @nestjs/cli@latest new api --package-manager npm --skip-install --skip-git
cd ..
```

### 4. Create the shared types package (`packages/types`)

```
packages/types/package.json
packages/types/src/index.ts
```

```json
{
  "name": "@<project-name>/types",
  "version": "1.0.0",
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts"
}
```

`src/index.ts` starts as `export {};` — add shared interfaces (e.g. request/response DTOs) here as both apps need them.

### 5. Wire the shared package into both apps

In `apps/web/package.json` and `apps/api/package.json`, add to `"dependencies"`:

```json
"@<project-name>/types": "*"
```

### 6. Add a `.gitignore`

```
node_modules/
dist/
build/
.next/
.env
.env.local
*.log
.DS_Store
Thumbs.db
**/*.tsbuildinfo
```

### 7. Add Postgres via Docker Compose

```yaml
services:
  db:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: <project-name>
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### 8. Install everything

From the repo root:

```bash
npm install
```

This resolves and hoists dependencies for the root, `apps/web`, `apps/api`, and `packages/types` together, and symlinks `@<project-name>/types` into both apps.

### 9. First run

```bash
docker compose up -d db
npm run dev
```

Confirm both apps boot, then make the first commit.

---

## Adding persistence (TypeORM + Postgres, optional)

Not wired up by default — add it once the project actually needs a database:

```bash
cd apps/api
npm install @nestjs/typeorm typeorm pg @nestjs/config dotenv
```

Then in `apps/api/src/app.module.ts`, register `TypeOrmModule.forRoot({...})` reading `DB_HOST` / `DB_PORT` / `DB_USERNAME` / `DB_PASSWORD` / `DB_NAME` from `apps/api/.env` (gitignored). Use `synchronize: true` in development only — it auto-creates/updates tables from entity files, so no manual migrations are needed while iterating.

## Adding auth (optional)

For JWT-based auth like other projects in this pattern: `@nestjs/jwt @nestjs/passport passport passport-jwt bcrypt` on the API side, plus a seed script (`seed-owner.ts`) to create the first user, since a fresh login-gated API has no way to create its own first account through the API itself.

---

## Day-to-day development workflow

### Start Postgres

```bash
docker compose up -d db
docker compose ps   # confirm it's up
```

### Start both apps

```bash
npm run dev
```

Both apps hot-reload on save — no restart needed. Backend code lives in `apps/api/src`, frontend in `apps/web/src`, shared types in `packages/types/src`.

### Stop everything

```bash
# Ctrl+C the dev process, then:
docker compose down
```

### Testing API endpoints (PowerShell)

`curl`'s quoting breaks under PowerShell — use `Invoke-RestMethod` instead:

```powershell
Invoke-RestMethod -Uri "http://localhost:3001/api/some-resource"

Invoke-RestMethod -Uri "http://localhost:3001/api/some-resource" -Method Post `
  -ContentType "application/json" -Body (@{ name = "Example" } | ConvertTo-Json)
```

Nested objects need `-Depth`, since PowerShell's JSON conversion only goes 2 levels deep by default:

```powershell
$body = @{ type = "x"; detail = @{ a = 1; b = 2 } } | ConvertTo-Json -Depth 5
```

### Working with the database directly

```bash
docker exec -it <project-name>-db-1 psql -U postgres -d <project-name> -P pager=off
```

`\dt` lists tables, `\d <table>` shows a table's structure.

### Adding a new backend resource (entity + CRUD)

1. `cd apps/api/src && nest g res my-resource --no-spec`
2. Define the entity in `my-resource/entities/my-resource.entity.ts`
3. Add validation to the DTOs in `my-resource/dto/`
4. Wire up the module — `TypeOrmModule.forFeature([...])` in `my-resource.module.ts`
5. Write the real service logic (the CLI only generates placeholders)
6. Add `ParseUUIDPipe` to any `:id` route params in the controller
7. Test it with `Invoke-RestMethod`

### Git workflow

- **`development`** — day-to-day working branch
- **`main`/`production`** — what's actually deployed

```bash
git add .
git commit -m "Clear description of what changed"
git push origin development
```

When ready to ship:

```bash
git checkout main
git merge development
git push origin main
git checkout development
```

---

## Deployment (self-hosted pattern)

For projects deployed the same way as other self-hosted apps in this setup:

1. Add a multi-stage `Dockerfile` to each app (`apps/web/Dockerfile`, `apps/api/Dockerfile`) with a `development` target (hot-reload, bind mounts) and a production build target.
2. Add `docker-compose.prod.yml` with explicit `ports:` bound to `127.0.0.1` for each service — needed if a reverse proxy or tunnel running on the host (not in Docker) connects to them, or you'll see `502` errors.
3. Keep production secrets (`JWT_*_SECRET`, `DB_PASSWORD`, etc.) in `.env` files created directly on the host, never committed or copied from local dev.
4. If serving frontend and API from one public origin, route `/api/*` to the API container and everything else to the frontend container at the reverse proxy/tunnel level — avoids CORS and cross-site cookie issues entirely.
5. Deploy with:
   ```bash
   git pull
   docker compose -f docker-compose.prod.yml up -d --build
   ```

---

## Quick reference

| Task                            | Command                                                                  |
| ------------------------------- | ------------------------------------------------------------------------ |
| Start Postgres only             | `docker compose up -d db`                                                |
| Start both apps (native)        | `npm run dev`                                                            |
| Start backend only              | `npm run dev:api`                                                        |
| Start frontend only             | `npm run dev:web`                                                        |
| Stop Docker containers          | `docker compose down`                                                    |
| Open a database shell           | `docker exec -it <project-name>-db-1 psql -U postgres -d <project-name>` |
| Scaffold a new backend resource | `nest g res <name> --no-spec` (run from `apps/api/src`)                  |
