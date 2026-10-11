# Errandly — Deployment & Environment Guide

Complete guide for setting up, running, and deploying all three Errandly applications.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Infrastructure Overview](#infrastructure-overview)
3. [Backend Setup (Laravel)](#backend-setup-laravel)
4. [Web Frontend Setup (Next.js)](#web-frontend-setup-nextjs)
5. [Mobile App Setup (Flutter)](#mobile-app-setup-flutter)
6. [Environment Variables Reference](#environment-variables-reference)
7. [Database Initialization](#database-initialization)
8. [Third-party Service Setup](#third-party-service-setup)
9. [Production Checklist](#production-checklist)
10. [Admin Access](#admin-access)

---

## System Requirements

### Backend
| Requirement | Minimum |
|-------------|---------|
| PHP | 8.2+ |
| PostgreSQL | 15+ |
| Redis | 7+ |
| Composer | 2.x |
| Node.js | 20+ (for Vite assets) |
| Memory | 512 MB RAM |

### Web Frontend
| Requirement | Version |
|-------------|---------|
| Node.js | 20+ |
| npm / pnpm | Latest |

### Mobile App
| Requirement | Version |
|-------------|---------|
| Flutter SDK | 3.3+ |
| Dart SDK | 3.3+ |
| Xcode | 15+ (iOS) |
| Android Studio | Hedgehog+ |
| Android SDK | API 33+ |

---

## Infrastructure Overview

```
Production Infrastructure
│
├── API Server (Laravel)
│   └── PHP-FPM + Nginx or Laravel Octane
│
├── Web Frontend (Next.js)
│   └── Dokploy Compose (web service) / Vercel / Node.js / PM2
│
├── Database
│   └── PostgreSQL (Dokploy Postgres, Prisma, Neon, RDS, etc.)
│
├── Cache + Queue + Sessions
│   └── Redis (Compose `redis` service or managed)
│
├── File Storage
│   └── AWS S3 (or compatible: DigitalOcean Spaces, Cloudflare R2)
│
├── Real-time
│   └── Pusher Channels
│
├── SMS / OTP
│   └── Twilio / Termii
│
├── Payments
│   └── Paystack (primary, Nigeria) + Stripe (optional)
│
├── Push Notifications
│   └── Firebase Cloud Messaging (FCM)
│
└── Queue Workers
    └── Compose `queue` + `scheduler` (or `php artisan queue:work`)
```

### Dokploy (full stack)

See [`../docker-compose.dokploy.yml`](../docker-compose.dokploy.yml) and [backend README — Dokploy](../backend/README.md#4-dokploy-recommended-compose).

| Piece | How |
|-------|-----|
| API + workers + Redis + Web | One Dokploy **Compose** project named **`errandlyapp`** |
| Postgres | Dokploy database **or** Compose profile `local-db` |
| TLS / domains | Dokploy Domains tab (`api`→80, `web`→3000) |
| Mobile | Not hosted on Dokploy — Play Store / App Store binaries |

---

## Backend Setup (Laravel)

### 1. Clone and install dependencies

```bash
cd errandly/backend
composer install --no-dev --optimize-autoloader
```

### 2. Environment configuration

```bash
cp .env.example .env
php artisan key:generate
php artisan jwt:secret
```

Edit `.env` with your actual values (see [Environment Variables Reference](#environment-variables-reference)).

### 3. Database setup

```bash
php artisan migrate --seed
```

This runs all 5 migrations and 5 seeders in order.

### 4. Storage

```bash
php artisan storage:link
```

### 5. Queue worker

```bash
php artisan horizon
```

Access Horizon dashboard at `/horizon` (admin only, gate configured in `HorizonServiceProvider`).

### 6. Telescope (development only)

```bash
php artisan telescope:install
php artisan migrate
```

Access at `/telescope`.

### 7. Start server

**Development:**
```bash
php artisan serve --port=8000
```

**Production (example with Nginx + PHP-FPM):**
```nginx
server {
    listen 80;
    server_name api.errandly.com;
    root /var/www/errandly/backend/public;

    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### 8. Optimize for production

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

---

## Web Frontend Setup (Next.js)

### 1. Install dependencies

```bash
cd errandly/web
npm install
```

### 2. Environment configuration

```bash
cp .env.example .env.local
```

Edit `.env.local` with your values.

### 3. Development

```bash
npm run dev
# Runs on http://localhost:3000
```

### 4. Production build

```bash
npm run build
npm run start
```

### 5. Deploy to Vercel (recommended)

```bash
vercel --prod
```

Set environment variables in the Vercel dashboard under Project Settings → Environment Variables.

---

## Mobile App Setup (Flutter)

### 1. Install dependencies

```bash
cd errandly/mobile
flutter pub get
```

### 2. Configure API URL

Edit `lib/core/constants/app_constants.dart`:
```dart
static const String apiBaseUrl = 'https://api.errandly.com/api';
static const String pusherKey = 'your_pusher_app_key';
static const String pusherCluster = 'mt1';
```

### 3. Firebase Setup

**Android:**
- Download `google-services.json` from Firebase Console.
- Place at `android/app/google-services.json`.

**iOS:**
- Download `GoogleService-Info.plist` from Firebase Console.
- Place at `ios/Runner/GoogleService-Info.plist`.

### 4. Android signing

Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=/path/to/your/keystore.jks
```

### 5. Build

**Android APK (debug):**
```bash
flutter build apk --debug
```

**Android App Bundle (release):**
```bash
flutter build appbundle --release
```

**iOS (release):**
```bash
flutter build ios --release
```
Then open `ios/Runner.xcworkspace` in Xcode and archive.

### 6. Run on device/emulator

```bash
flutter run                    # Debug on connected device
flutter run --release          # Release mode
flutter run -d emulator-id     # Specific emulator
```

---

## Environment Variables Reference

### Backend (`.env`)

```env
# Application
APP_NAME=Errandly
APP_ENV=production              # local | staging | production
APP_KEY=                        # Generated: php artisan key:generate
APP_DEBUG=false                 # false in production
APP_URL=https://api.errandly.com
APP_TIMEZONE=UTC

# Logging
LOG_CHANNEL=stack
LOG_LEVEL=error                 # error in production, debug in dev

# Database (PostgreSQL)
DB_CONNECTION=pgsql
DB_HOST=your_db_host
DB_PORT=5432
DB_DATABASE=errandly
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password

# Cache & Queue
BROADCAST_DRIVER=pusher
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

# Redis
REDIS_HOST=your_redis_host
REDIS_PASSWORD=your_redis_password
REDIS_PORT=6379

# Mail
MAIL_MAILER=smtp
MAIL_HOST=your_smtp_host
MAIL_PORT=587
MAIL_USERNAME=your_smtp_user
MAIL_PASSWORD=your_smtp_password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@errandly.com
MAIL_FROM_NAME=Errandly

# AWS S3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=errandly-uploads
AWS_USE_PATH_STYLE_ENDPOINT=false

# Pusher Channels
PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=mt1

# JWT
JWT_SECRET=                     # Generated: php artisan jwt:secret
JWT_TTL=60                      # Minutes
JWT_REFRESH_TTL=20160           # 14 days in minutes

# Twilio (SMS/OTP)
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM=+1234567890         # Your Twilio phone number

# Paystack
PAYSTACK_SECRET_KEY=sk_live_...
PAYSTACK_PUBLIC_KEY=pk_live_...
PAYSTACK_WEBHOOK_SECRET=

# Stripe (optional)
STRIPE_KEY=pk_live_...
STRIPE_SECRET=sk_live_...
STRIPE_WEBHOOK_SECRET=

# Platform Config
PLATFORM_COMMISSION_RATE=0.15
PLATFORM_MIN_ERRAND_AMOUNT=500
PLATFORM_CURRENCY=NGN

# Frontend URLs
FRONTEND_URL=https://app.errandly.com
MOBILE_DEEP_LINK_URL=errandly://

# Admin Tools
TELESCOPE_ENABLED=false         # false in production
HORIZON_ENABLED=true
```

### Web Frontend (`.env.local`)

```env
NEXT_PUBLIC_API_URL=https://api.errandly.com/api
NEXT_PUBLIC_PUSHER_APP_KEY=your_pusher_key
NEXT_PUBLIC_PUSHER_CLUSTER=mt1
NEXT_PUBLIC_PUSHER_HOST=
NEXT_PUBLIC_PUSHER_PORT=443
NEXT_PUBLIC_PUSHER_SCHEME=https
NEXT_PUBLIC_APP_NAME=Errandly
NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY=pk_live_...
```

---

## Database Initialization

### Fresh setup

```bash
php artisan migrate:fresh --seed
```

> **Warning:** This drops all tables. For production, use `migrate --seed` instead.

### Seeders explanation

| Seeder | Creates |
|--------|---------|
| `RolesAndPermissionsSeeder` | 4 Spatie roles: customer, runner, admin, verification_officer |
| `SettingsSeeder` | Default platform settings (commission rate, currency, etc.) |
| `ServiceAreaSeeder` | 5 Uyo (Akwa Ibom) service areas with center coordinates |
| `AdminUserSeeder` | admin@errandly.com + kyc@errandly.com accounts |
| `TestUsersSeeder` | Sample customer and runner for development |

### Run individual seeder

```bash
php artisan db:seed --class=ServiceAreaSeeder
```

---

## Third-party Service Setup

### Pusher Channels
1. Create account at [pusher.com](https://pusher.com).
2. Create a new app.
3. Copy App ID, Key, Secret, Cluster into `.env`.
4. Enable the Channels API (not Beams, not Chatkit).

### Twilio (SMS OTP)
1. Create account at [twilio.com](https://twilio.com).
2. Get a phone number.
3. Copy Account SID, Auth Token, and phone number into `.env`.

### Paystack
1. Create account at [paystack.com](https://paystack.com).
2. From Dashboard → Settings → API Keys & Webhooks.
3. Copy Secret Key and Public Key.
4. Set webhook URL to: `https://api.errandly.com/api/webhooks/paystack`.

### AWS S3
1. Create S3 bucket `errandly-uploads` in your chosen region.
2. Set bucket policy to allow `s3:GetObject` for public reads (for profile images, proof photos).
3. Create IAM user with `AmazonS3FullAccess` for the application credentials.

### Firebase (Push Notifications)
1. Create project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add Android app (package: `com.errandly.app`) and iOS app (bundle ID: `com.errandly.app`).
3. Download config files and place in mobile project (see [Mobile Setup](#mobile-app-setup-flutter)).
4. For backend push: download service account JSON and configure FCM in Laravel.

---

## Production Checklist

### Security
- [ ] `APP_DEBUG=false`
- [ ] `APP_ENV=production`
- [ ] `TELESCOPE_ENABLED=false`
- [ ] All secrets rotated from development values
- [ ] HTTPS enforced (SSL certificate installed)
- [ ] CORS configured to allow only known frontend origins
- [ ] Rate limiting enabled on auth routes
- [ ] Pusher webhook secret configured
- [ ] Paystack webhook signature verification enabled

### Performance
- [ ] `php artisan config:cache` run
- [ ] `php artisan route:cache` run
- [ ] `php artisan view:cache` run
- [ ] `php artisan event:cache` run
- [ ] OPcache enabled in PHP-FPM
- [ ] Redis connection pool configured
- [ ] Database connection pool configured (PgBouncer recommended)

### Background Jobs
- [ ] Laravel Horizon running via Supervisor
- [ ] Horizon queue workers configured for capacity
- [ ] Horizon failure alerts set up

### Monitoring
- [ ] Application error monitoring (e.g. Sentry) integrated
- [ ] Laravel Horizon dashboard secured with gate
- [ ] PostgreSQL slow query logging enabled
- [ ] Redis memory alerts configured

### Mobile
- [ ] `apiBaseUrl` pointing to production API
- [ ] Firebase production config files in place
- [ ] Android app signed with release keystore
- [ ] iOS app provisioning profile set for distribution
- [ ] App Store / Play Store metadata prepared

---

## Admin Access

| Role | Email | Password | Access |
|------|-------|----------|--------|
| Admin | admin@errandly.com | Admin@1234 | Full platform access |
| KYC Officer | kyc@errandly.com | Kyc@Officer1234 | KYC review + runner approval only |

> **Important:** Change these passwords immediately after first login in production.

**Admin dashboard URL:** `https://app.errandly.com/admin/dashboard`

**Horizon (queue monitor):** `https://api.errandly.com/horizon`

**Telescope (dev only):** `http://localhost:8000/telescope`
