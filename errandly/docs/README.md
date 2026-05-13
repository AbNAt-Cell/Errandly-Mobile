# Errandly — Hyperlocal Errand Marketplace

Errandly is a trust-first hyperlocal errand marketplace that connects customers who need tasks done with verified runners who complete them for a fee. The platform launches in Uyo, Akwa Ibom State, Nigeria, with plans to expand to other cities.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Repository Structure](#repository-structure)
5. [Launch Cities & Configuration](#launch-cities--configuration)
6. [Core Business Rules](#core-business-rules)
7. [Errand Lifecycle](#errand-lifecycle)
8. [User Roles](#user-roles)
9. [Getting Started](#getting-started)
10. [Default Credentials](#default-credentials)
11. [Documentation Index](#documentation-index)

---

## Project Overview

Errandly allows customers to post errands (deliveries, purchases, queue-standing, document collection, etc.) and have them fulfilled by verified local runners. Every transaction is protected by an escrow wallet, OTP-based handoffs, live GPS tracking, a panic button, and a comprehensive dispute resolution system.

**Key design principles:**
- Money is never moved until the customer explicitly confirms delivery via OTP
- Runners are scored by a Trust Score system — affecting their visibility and errand access
- All runner onboarding requires KYC verification before they can accept live errands
- The panic button immediately freezes escrow and alerts admins in real time

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
│  ┌──────────────────┐          ┌───────────────────────────┐   │
│  │  Flutter Mobile  │          │  Next.js Web Dashboard    │   │
│  │  (Customer &     │          │  (Customer, Runner, Admin) │   │
│  │   Runner)        │          │                           │   │
│  └────────┬─────────┘          └─────────────┬─────────────┘   │
└───────────┼─────────────────────────────────-┼─────────────────┘
            │  REST API + WebSocket (Pusher)    │
┌───────────┼──────────────────────────────────┼─────────────────┐
│           ▼       BACKEND LAYER               ▼                 │
│  ┌──────────────────────────────────────────────────────┐      │
│  │              Laravel 11 API (PHP 8.2)                │      │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────┐  │      │
│  │  │  Services   │  │  Controllers │  │   Events   │  │      │
│  │  │  (Business  │  │  (REST API   │  │  (Pusher   │  │      │
│  │  │   Logic)    │  │   Handlers)  │  │  Channels) │  │      │
│  │  └─────────────┘  └──────────────┘  └────────────┘  │      │
│  └────────────────────────────┬─────────────────────────┘      │
│                               │                                 │
│  ┌────────────────────────────┼─────────────────────────┐      │
│  │         DATA LAYER         │                          │      │
│  │  ┌──────────────┐    ┌─────┴──────┐  ┌───────────┐  │      │
│  │  │  PostgreSQL  │    │   Redis    │  │  AWS S3   │  │      │
│  │  │  (Primary    │    │  (Queue,   │  │  (Media   │  │      │
│  │  │   Database)  │    │  Cache,    │  │  Storage) │  │      │
│  │  │              │    │  Sessions) │  │           │  │      │
│  │  └──────────────┘    └────────────┘  └───────────┘  │      │
│  └──────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Backend API | Laravel (PHP) | 11.x / PHP 8.2 |
| Web Frontend | Next.js (React) | 14.2 |
| Mobile App | Flutter | SDK ≥3.3 |
| Database | PostgreSQL | 15+ |
| Cache / Queue / Sessions | Redis | 7+ |
| Real-time / WebSockets | Pusher Channels | — |
| File Storage | AWS S3 | — |
| SMS / OTP | Twilio | — |
| Payments | Paystack / Stripe | — |
| Auth (API) | Laravel Sanctum + JWT | — |
| Background Jobs | Laravel Horizon | 5.x |
| Observability | Laravel Telescope | 5.x |
| Permissions | Spatie Laravel Permission | 6.x |
| Media | Spatie Media Library | 11.x |

---

## Repository Structure

```
errandly/
├── backend/          # Laravel 11 API server
├── web/              # Next.js 14 web dashboard
├── mobile/           # Flutter mobile application
└── docs/             # This documentation
    ├── README.md               ← You are here
    ├── BACKEND.md              ← Backend deep-dive
    ├── FRONTEND.md             ← Web frontend deep-dive
    ├── MOBILE.md               ← Flutter app deep-dive
    ├── API_REFERENCE.md        ← Full REST API endpoints
    ├── DATABASE_SCHEMA.md      ← All tables, columns, relationships
    └── DEPLOYMENT.md           ← Environment setup & deployment
```

---

## Launch Cities & Configuration

**Launch city:** Uyo, Akwa Ibom State (expanding to other cities over time)

**Service areas (seeded):**
- Uyo City Centre
- Ewet Housing
- Use Offot
- Ikot Ekpene Road
- Ring Road

**Business configuration:**

| Setting | Value | Env variable |
|---------|-------|-------------|
| Commission rate | 15% | `PLATFORM_COMMISSION_RATE` |
| Minimum errand amount | ₦500 | `PLATFORM_MIN_ERRAND_AMOUNT` |
| Currency | NGN | `PLATFORM_CURRENCY` |
| Runner search radius | 15 km | hardcoded in config |
| Errand acceptance timeout | 30 minutes | config |
| Minimum withdrawal | ₦1,000 | config |
| OTP expiry | 1 hour (3,600 s) | config |
| Auth OTP expiry | 10 minutes (600 s) | config |

---

## Core Business Rules

### Payments & Escrow
- When a customer posts an errand, the full amount (budget + 15% platform fee) is immediately debited from their wallet into escrow using a DB transaction with `lockForUpdate()`.
- Funds remain frozen in escrow for the entire lifecycle of the errand.
- Escrow is released to the runner only after the customer verifies the delivery OTP.
- If the customer cancels before a runner accepts, they receive a 100% refund.
- If cancelled after acceptance, they receive budget only (platform fee is forfeited).
- If cancelled after the runner is en route, they receive 50% of the total.
- Panic events immediately freeze the escrow and lock it until an admin resolves it.

### OTP Handoffs (two-factor delivery verification)
1. **Pickup OTP** — generated when the runner arrives at the pickup point; sent to the customer; runner enters it to confirm item handoff.
2. **Delivery OTP** — generated when the runner submits proof of task completion; sent to the customer; customer enters it to release payment.

Both OTPs are 6-digit codes, stored as bcrypt hashes in the DB, and the plain value is held in Redis cache for 1 hour.

### Trust Score
Runners start at a score of 70/100. The score is recalculated after every completed errand using a weighted formula:

| Factor | Weight |
|--------|--------|
| Completion rate | 30% |
| Average rating | 30% |
| Cancellation penalty | 20% |
| Dispute penalty | 15% |
| Response time | 5% |

**Penalties (deducted immediately):**
- Runner cancellation: −5 points
- Dispute raised against runner: −10 points
- Safety incident: −20 points
- Fake proof submission: −25 points

**Bonuses:**
- 10 errands milestone: +5 points
- 50 errands milestone: +10 points

### KYC Verification
Runners cannot accept errands until their KYC is approved. The KYC lifecycle:
`pending → submitted → under_review → approved / rejected / resubmission_required`

For runners, required documents include: NIN, BVN, government ID, selfie/live photo, address proof, guarantor details.

### Dispute Resolution
Dispute types: `item_not_delivered`, `item_damaged`, `wrong_task_execution`, `harassment`, `fraudulent_completion`, `missing_payment`, `other`.

Resolution types: `refund`, `release`, `partial_refund`, `no_action`.

Admins/KYC officers can assign disputes, collect evidence (photo/video/document/text), and resolve them with automated escrow actions.

---

## Errand Lifecycle

```
CUSTOMER POSTS ERRAND
        │
        ▼
    [posted]
        │ (escrow locks funds)
        ▼
[pending_assignment] ──► NotifyNearbyRunners job broadcasts to eligible runners
        │
        │ Runner accepts (race-condition-safe lockForUpdate)
        ▼
    [accepted]
        │
        │ Runner marks "arrived at pickup"
        ▼
[runner_en_route] ──► Pickup OTP sent to customer
        │
        │ Runner enters pickup OTP (verifies item handoff)
        ▼
  [item_picked]
        │
        │ Runner starts errand
        ▼
  [in_progress] ──► Live tracking active
        │
        │ Runner submits proof + completes task
        ▼
[awaiting_confirmation] ──► Delivery OTP sent to customer
        │
        │ Customer enters delivery OTP
        ▼
  [completed] ──► Escrow released to runner ──► Trust score updated
```

**Terminal states (from various points):**
- `cancelled` — customer or admin cancels (partial/full refund)
- `failed` — system/runner failure
- `disputed` — panic button or manual dispute
- `refunded` — admin resolves dispute in customer's favour

---

## User Roles

| Role | Permissions |
|------|------------|
| `customer` | Post errands, track runners, manage wallet, chat, rate runners, raise disputes |
| `runner` | Accept errands, update location, verify OTPs, submit proof, withdraw earnings |
| `admin` | Full platform access: users, runners, KYC, errands, finance, disputes, reports, settings |
| `verification_officer` | KYC review and runner approval only |

---

## Getting Started

See [DEPLOYMENT.md](./DEPLOYMENT.md) for full environment setup.

**Quick start:**

```bash
# Backend
cd errandly/backend
cp .env.example .env
composer install
php artisan key:generate
php artisan jwt:secret
php artisan migrate --seed
php artisan serve

# Web
cd errandly/web
npm install
npm run dev

# Mobile
cd errandly/mobile
flutter pub get
flutter run
```

---

## Default Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@errandly.com | Admin@1234 |
| KYC Officer | kyc@errandly.com | Kyc@Officer1234 |

---

## Documentation Index

| File | Contents |
|------|---------|
| [BACKEND.md](./BACKEND.md) | Services, controllers, events, jobs, middleware, seeders |
| [FRONTEND.md](./FRONTEND.md) | Next.js pages, layouts, state management, components |
| [MOBILE.md](./MOBILE.md) | Flutter screens, navigation, services, packages |
| [API_REFERENCE.md](./API_REFERENCE.md) | All REST endpoints with methods, auth requirements, parameters |
| [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) | Every table with columns, types, indexes, and relationships |
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Server requirements, environment variables, production checklist |
