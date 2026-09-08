# Errandly Backend API

Laravel 11 REST API for **Errandly** — a trust-first hyperlocal errand marketplace. Customers post errands (deliveries, purchases, queue-standing, document runs, etc.); verified runners fulfill them; money moves through an escrow wallet with OTP handoffs, live tracking, disputes, and admin oversight.

**Clients:** Flutter mobile app (customer + runner) and Next.js web dashboard (customer, runner, admin).

**Base URL:** `{APP_URL}/api`  
**Health check:** `{APP_URL}/up`

Full endpoint reference: [`../docs/API_REFERENCE.md`](../docs/API_REFERENCE.md)

---

## Table of Contents

1. [What the API Does](#what-the-api-does)
2. [How It Works](#how-it-works)
3. [Tech Stack](#tech-stack)
4. [Project Structure](#project-structure)
5. [Authentication & Authorization](#authentication--authorization)
6. [API Modules](#api-modules)
7. [Integrations](#integrations)
8. [Local Development](#local-development)
9. [Deployment](#deployment)
10. [Environment Variables](#environment-variables)
11. [Production Checklist](#production-checklist)
12. [Default Test Accounts](#default-test-accounts)
13. [Further Documentation](#further-documentation)

---

## What the API Does

Errandly connects people who need tasks done with local runners who complete them for a fee. The backend is the **single source of truth** for:

- **User accounts** — customers, runners, admins, KYC officers
- **Errand lifecycle** — post → assign → pickup → in progress → proof → OTP confirmation → payout
- **Money** — wallet balances, escrow holds, platform commission (15%), refunds, runner withdrawals
- **Trust & safety** — KYC, runner trust scores, panic button, dispute resolution
- **Real-time** — Pusher channels for tracking, messages, notifications
- **AI assistance** — Gemini-powered errand drafting, budget suggestions, proof/KYC analysis, dispute summaries (optional)

Launch geography is **Uyo, Akwa Ibom, Nigeria** (expandable via service-area settings).

---

## How It Works

### Request flow

```
Client (mobile / web)
    │  HTTPS  Authorization: Bearer {sanctum_token}
    ▼
Nginx → PHP-FPM → Laravel Router (routes/api.php)
    │                    │
    │                    ├─ Middleware: auth:sanctum, role:*, runner.verified
    │                    ▼
    │              Controllers (thin)
    │                    ▼
    │              Services (business logic)
    │                    ├─ ErrandService, WalletService, PaymentService
    │                    ├─ TrustScoreService, KycService, NotificationService
    │                    └─ Ai/* (Gemini tools, vision, proposals)
    │                    ▼
    │              PostgreSQL (primary data)
    │              Redis (cache, sessions, queues, OTP cache)
    │              S3 (media) · Pusher (realtime) · FCM (push)
    ▼
JSON response
```

### Errand lifecycle (simplified)

```
posted → pending_assignment → accepted → runner_en_route → item_picked
    → in_progress → awaiting_confirmation → completed
```

Branches: `cancelled`, `failed`, `disputed`, `refunded`.

**Money rule:** When a customer posts an errand, budget + platform fee is debited into **escrow**. Funds release to the runner only after the customer confirms delivery with a **delivery OTP**. Pickup uses a separate **pickup OTP** when the runner arrives.

**Trust:** Runners need **approved KYC** before accepting live errands (`runner.verified` middleware). Trust score affects matching and visibility.

### Background processing

| Process | Driver | Purpose |
|---------|--------|---------|
| Queue worker | Redis + `queue:work` | Async jobs (notifications, payments, AI) |
| Scheduler | `schedule:run` every minute | Recurring tasks |
| Webhooks | `POST /api/webhooks/*` | Paystack, Flutterwave, Stripe callbacks |

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Laravel 11, PHP 8.2+ |
| Database | PostgreSQL 15+ (`pdo_pgsql` required) |
| Cache / queue / sessions | Redis 7+ |
| Auth | Laravel Sanctum (Bearer tokens) |
| Roles | Spatie Laravel Permission |
| Payments | Paystack (primary), Flutterwave, Stripe |
| SMS / OTP | Termii, Twilio |
| Push | Firebase Cloud Messaging (HTTP v1) |
| Realtime | Pusher Channels |
| Media | Spatie Media Library + AWS S3 |
| AI | Google Gemini (optional, `AI_AGENT_ENABLED`) |

---

## Project Structure

```
backend/
├── app/
│   ├── Http/Controllers/Api/    # REST handlers (auth, errands, wallet, …)
│   ├── Http/Controllers/Admin/  # Admin dashboard API
│   ├── Http/Middleware/         # role, runner.verified, throttle.ai
│   ├── Models/                  # Eloquent models
│   ├── Services/                # Business logic
│   │   ├── ErrandService.php
│   │   ├── WalletService.php
│   │   ├── PaymentService.php
│   │   └── Ai/                  # Gemini agent, vision, tools
│   └── Events/                  # Pusher broadcast events
├── routes/api.php               # All API routes (prefix /api)
├── database/migrations/         # Schema
├── database/seeders/            # Roles, admin, test users, settings
├── config/                      # database, sanctum, errandly, services
├── docker/                      # Nginx, PHP, entrypoint for containers
├── Dockerfile
├── docker-compose.yml           # API + Postgres + Redis + workers
└── .env.example                 # Full env template
```

---

## Authentication & Authorization

### Login

`POST /api/auth/login`

```json
{
  "login": "email or phone",
  "password": "string",
  "device_token": "optional FCM token",
  "device_id": "optional",
  "device_type": "ios|android|web"
}
```

Response includes `token`, `user`, and `roles`.

### Using the token

```
Authorization: Bearer {token}
Accept: application/json
```

### Roles (Spatie)

| Role | Access |
|------|--------|
| `customer` | `/api/customer/*` — post errands, wallet, tracking |
| `runner` | `/api/runner/*` — accept errands, earnings (requires KYC approval for live errands) |
| `admin`, `super_admin` | `/api/admin/*` — users, finance, disputes, reports |
| `verification_officer` | Admin KYC and runner approval subset |

---

## API Modules

| Prefix | Description |
|--------|-------------|
| `/auth` | Register, login, logout, profile, phone OTP, device tokens |
| `/kyc` | Identity verification status and document submission |
| `/customer/errands` | Create, list, cancel, confirm completion, panic, proof |
| `/customer/payments` | Initialize Paystack/Flutterwave payments, verify |
| `/runner/errands` | Available jobs, accept/reject, pickup OTP, proof, complete |
| `/runner/earnings` | Balance, withdraw, bank account |
| `/wallet` | Balance, transactions, fund, escrow view |
| `/messages` | Per-errand chat (text + voice) |
| `/notifications` | In-app notification inbox |
| `/ratings` | Post-errand ratings |
| `/disputes` | Open disputes, add evidence |
| `/ai` | Errand parsing, budget suggestions, agent chat (throttled) |
| `/admin` | Dashboard, users, runners, KYC, finance, reports, settings |
| `/webhooks` | Payment gateway callbacks (signature-verified, no auth) |

Errands are addressed by **public_id** in URLs (route model binding).

---

## Integrations

Configure in `.env` (see `.env.example`):

| Service | Env keys | Used for |
|---------|----------|----------|
| Paystack | `PAYSTACK_*` | Card, bank transfer, USSD, NGN payouts |
| Flutterwave | `FLUTTERWAVE_*` | Alternate payment channels |
| Stripe | `STRIPE_*` | International cards |
| Termii / Twilio | `TERMII_*`, `TWILIO_*` | SMS OTP |
| Pusher | `PUSHER_*` | Live tracking, messages |
| Firebase | `FIREBASE_*` | Push notifications |
| AWS S3 | `AWS_*` | Proof photos, KYC documents |
| Gemini | `GEMINI_*`, `AI_*` | AI features |

Webhook URLs (production):

- `https://your-api-domain/api/webhooks/paystack`
- `https://your-api-domain/api/webhooks/flutterwave`
- `https://your-api-domain/api/webhooks/stripe`

---

## Local Development

### Prerequisites

- PHP 8.2+ with extensions: `pdo_pgsql`, `redis`, `mbstring`, `xml`, `curl`, `zip`, `gd`, `bcmath`
- Composer 2.x
- PostgreSQL 15+ and Redis 7+ (local or Docker)

### Setup

This repository **is** the backend — clone it and work from the repo root (no `errandly/backend` subfolder).

```bash
git clone https://github.com/AbNAt-Cell/Errandly.git
cd Errandly
cp .env.example .env

composer install
php artisan key:generate
php artisan jwt:secret

# Configure DB_* or DATABASE_URL and REDIS_* in .env, then:
php artisan migrate --seed

php artisan serve
# API: http://localhost:8000/api
```

### Run queue & scheduler (separate terminals)

```bash
php artisan queue:work redis
php artisan schedule:work
```

---

## Deployment

Errandly supports **Docker** (recommended) and **traditional PHP hosting** (cPanel/VPS with Nginx + PHP-FPM).

### Option A — Docker (recommended)

Best for VPS, Railway, Render, Fly.io, or any host with Docker.

#### 1. Prepare environment

```bash
cp .env.docker.example .env
```

Edit `.env`:

- Set `APP_KEY` (`php artisan key:generate` on a machine with PHP)
- Set `JWT_SECRET` (`php artisan jwt:secret`)
- For **bundled Postgres** (default compose): leave `DB_HOST=postgres`, `REDIS_HOST=redis`
- For **external Postgres** (Prisma, Supabase, RDS): set `DATABASE_URL` and use production compose override

#### 2. Development / staging stack (API + Postgres + Redis + workers)

```bash
docker compose up -d --build
```

| URL | Purpose |
|-----|---------|
| http://localhost:8000 | API root |
| http://localhost:8000/up | Health check |
| http://localhost:8000/api | API base |

Services started:

| Service | Role |
|---------|------|
| `api` | Nginx + PHP-FPM (port `${API_PORT:-8000}`) |
| `postgres` | PostgreSQL 16 |
| `redis` | Cache, sessions, queues |
| `queue` | `php artisan queue:work` |
| `scheduler` | Laravel scheduler loop |

Container bootstrap flags (in `.env`):

| Variable | Description |
|----------|-------------|
| `RUN_MIGRATIONS` | Run `migrate --force` on api container start |
| `RUN_SEEDERS` | Run `db:seed` on api container start |
| `WAIT_FOR_DB` | Wait for Postgres before boot |
| `CACHE_CONFIG` | Cache config/routes/views when `APP_ENV=production` |

#### 3. Production with Docker

Use the included production override (disables local Postgres profile, production env defaults):

```bash
# .env — point at managed Postgres + Redis
DATABASE_URL=postgres://USER:PASS@your-host:5432/errandly?sslmode=require
REDIS_HOST=your-redis-host

APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.yourdomain.com
RUN_MIGRATIONS=false    # run manually on first deploy only
RUN_SEEDERS=false
TELESCOPE_ENABLED=false

docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

**First production deploy** — run migrations once:

```bash
docker compose exec api php artisan migrate --force
# Optional: docker compose exec api php artisan db:seed --class=AdminUserSeeder --force
```

**Ongoing deploys** after code changes:

```bash
git pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build api queue scheduler
docker compose exec api php artisan migrate --force
```

#### 4. Dokploy (recommended: Compose)

Prefer a **single Compose service** named **`errandlyapp`** so API, queue, scheduler, Redis, and Web deploy together.

**Monorepo** (`errandly/` under the git root):

| Dokploy setting | Value |
|-----------------|-------|
| Service name | `errandlyapp` |
| Service type | **Compose** → Docker Compose |
| Compose path | `./errandly/docker-compose.dokploy.yml` |
| Env template | [`errandly/.env.dokploy.example`](../.env.dokploy.example) |

**If this Laravel folder is the git root** (standalone backend repo), use the single-app Dockerfile path below instead, or mirror the compose file with adjusted contexts.

Compose services: `api` (port **80**), `web` (port **3000**), `queue`, `scheduler`, `redis`. Optional `postgres` via Compose profile **`local-db`**.

1. Create a Dokploy **Postgres** database (or use Prisma / Neon). Copy the **internal** hostname into `DATABASE_URL` / `DB_HOST` — never `localhost`.
2. Paste env from `.env.dokploy.example` into Dokploy → Environment. Generate `APP_KEY` and `JWT_SECRET`.
3. Domains tab: point `api.yourdomain.com` → service **api** port **80**; `app.yourdomain.com` → **web** port **3000**.
4. First deploy: `RUN_MIGRATIONS=true`, deploy once, then set `RUN_MIGRATIONS=false`.
5. Rebuild **web** whenever `NEXT_PUBLIC_*` values change (they are baked at image build).

All services join external network `dokploy-network` (created by Dokploy). Do **not** set `container_name`.

##### Alternative: single Dockerfile (API only)

| Dokploy setting | Value |
|-----------------|-------|
| Build type | Dockerfile |
| Dockerfile path | `Dockerfile` (this directory) |
| Build context | `.` |
| Exposed port | `80` |

You must still provide **Redis** plus separate worker/scheduler processes (same image):

- Queue: `php artisan queue:work redis --sleep=3 --tries=3 --max-time=3600`
- Scheduler: `sh -c "while true; do php artisan schedule:run --verbose --no-interaction; sleep 60; done"`

```env
APP_KEY=base64:...
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.yourdomain.com
DATABASE_URL=postgres://...
REDIS_HOST=...
TELESCOPE_ENABLED=false
RUN_MIGRATIONS=true
RUN_SEEDERS=false
WAIT_FOR_DB=true
```

Or use `docker-compose.yml` on a VPS with `docker compose up -d` instead of Dokploy.

#### 5. Docker image only (other PaaS)

```bash
docker build -t errandly-api:latest .
docker run --env-file .env -p 8000:80 errandly-api:latest
```

Provide `DATABASE_URL`, `REDIS_HOST`, `APP_KEY`, and payment keys via the platform’s environment UI. Run a separate worker process with the same image:

```bash
php artisan queue:work redis --sleep=3 --tries=3
```

#### 6. Useful Docker commands

```bash
docker compose logs -f api
docker compose exec api php artisan migrate --force
docker compose exec api php artisan db:seed --force
docker compose exec api php artisan config:clear
docker compose down          # stop
docker compose down -v       # stop + delete volumes (destroys local DB)
```

---

### Option B — Traditional hosting (cPanel / VPS)

Use when Docker is not available (e.g. shared hosting).

#### Requirements on the server

- PHP **8.2+** with **`pdo_pgsql`** and **`pgsql`** enabled (verify via phpinfo or cPanel → Select PHP Version → Extensions)
- Document root → `public/` (not project root)
- Writable: `storage/`, `bootstrap/cache/`
- Outbound access to Postgres (port 5432) if using remote DB (Prisma, Supabase)
- Redis optional but recommended for queues/cache (or use `file` / `database` drivers for small deployments)

#### Deploy steps

1. Upload code to server (Git, FTP, or CI). **Do not** commit `.env`.
2. Run on server (SSH or local against remote DB):
   ```bash
   composer install --no-dev --optimize-autoloader
   php artisan key:generate
   php artisan jwt:secret
   php artisan migrate --force
   php artisan db:seed --force   # staging only; skip in production or seed admin only
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```
3. If **no SSH** (shared hosting only):
   - Edit `.env` in File Manager
   - Delete `bootstrap/cache/config.php` after `.env` changes (manual `config:clear`)
   - Run migrations from your PC if the DB allows remote connections:
     ```bash
     # Use same DATABASE_URL as live .env
     php artisan migrate --force
     php artisan db:seed --force
     ```
4. Set permissions: `storage/` and `bootstrap/cache/` → writable by web server user.
5. Configure cron (scheduler):
   ```
   * * * * * cd /path/to/Errandly && php artisan schedule:run >> /dev/null 2>&1
   ```
6. Run a queue worker via cron or supervisor (if Redis configured):
   ```
   php artisan queue:work redis --stop-when-empty
   ```
   For production, use Supervisor or a persistent worker process.

#### Postgres SSL on shared hosting

| Database | `DATABASE_URL` sslmode |
|----------|------------------------|
| Prisma / Supabase / cloud | `sslmode=require` |
| cPanel local Postgres | `sslmode=disable` or `prefer` |

Example Prisma:

```env
DB_CONNECTION=pgsql
DATABASE_URL=postgres://USER:PASS@pooled.db.prisma.io:5432/postgres?sslmode=require
```

Example cPanel local:

```env
DB_CONNECTION=pgsql
DATABASE_URL=postgres://user:pass@localhost:5432/dbname?sslmode=disable
```

#### Production `.env` essentials

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.yourdomain.com

DB_CONNECTION=pgsql
DATABASE_URL=...

CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
REDIS_HOST=...

TELESCOPE_ENABLED=false
```

---

## Environment Variables

Copy `.env.example` and fill in values. Critical groups:

| Group | Variables |
|-------|-----------|
| App | `APP_KEY`, `APP_URL`, `APP_ENV`, `APP_DEBUG` |
| Database | `DB_CONNECTION=pgsql`, `DATABASE_URL` or `DB_HOST` / `DB_*` |
| Redis | `REDIS_HOST`, `REDIS_PASSWORD`, `REDIS_PORT` |
| Auth | `JWT_SECRET` (if using JWT helpers), Sanctum uses `APP_KEY` |
| Payments | `PAYSTACK_*`, `FLUTTERWAVE_*`, `STRIPE_*` |
| SMS | `TERMII_*`, `TWILIO_*` |
| Realtime | `PUSHER_*` |
| Push | `FIREBASE_*` |
| Storage | `AWS_*`, `FILESYSTEM_DISK=s3` (production) |
| AI | `GEMINI_API_KEY`, `AI_AGENT_ENABLED` |
| Platform | `PLATFORM_COMMISSION_RATE`, `PLATFORM_MIN_ERRAND_AMOUNT` |

See [`.env.example`](.env.example) and [`../docs/DEPLOYMENT.md`](../docs/DEPLOYMENT.md) for the full list.

---

## Production Checklist

- [ ] `APP_ENV=production`, `APP_DEBUG=false`
- [ ] `APP_KEY` and `JWT_SECRET` set (unique per environment)
- [ ] PostgreSQL reachable with correct `sslmode`
- [ ] `php artisan migrate --force` applied
- [ ] Redis running; `QUEUE_CONNECTION=redis`
- [ ] Queue worker + scheduler running
- [ ] `TELESCOPE_ENABLED=false` (or restricted)
- [ ] Payment webhooks registered with gateway dashboards
- [ ] `APP_URL` matches public API domain (HTTPS)
- [ ] CORS / `FRONTEND_URL` set for web client
- [ ] S3 bucket configured for uploads (production)
- [ ] Firebase credentials for push (if using mobile notifications)
- [ ] Default seed passwords changed after first login

---

## Default Test Accounts

Created by `TestUsersSeeder` and `AdminUserSeeder` when `php artisan db:seed` runs (non-production or explicit seed):

| Role | Login | Password |
|------|-------|----------|
| Customer | `customer@test.com` | `Test@1234` |
| Runner | `runner@test.com` | `Test@1234` |
| Admin | `admin@errandly.com` | `Admin@1234` |
| KYC Officer | `kyc@errandly.com` | `Kyc@Officer1234` |

**Change these immediately in any shared or production environment.**

---

## Further Documentation

| Document | Contents |
|----------|----------|
| [`../docs/API_REFERENCE.md`](../docs/API_REFERENCE.md) | Every endpoint, request/response shapes |
| [`../docs/BACKEND.md`](../docs/BACKEND.md) | Services, events, jobs, middleware deep dive |
| [`../docs/DATABASE_SCHEMA.md`](../docs/DATABASE_SCHEMA.md) | Tables and relationships |
| [`../docs/DEPLOYMENT.md`](../docs/DEPLOYMENT.md) | Full-stack deployment (web + mobile + backend) |
| [`../docs/README.md`](../docs/README.md) | Product overview, business rules, errand lifecycle |

---

## License

MIT
