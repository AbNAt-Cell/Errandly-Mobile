# Errandly — Backend Documentation

Laravel 11 / PHP 8.2 REST API powering the Errandly platform.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Models](#models)
3. [Services](#services)
4. [API Controllers](#api-controllers)
5. [Admin Controllers](#admin-controllers)
6. [Events](#events)
7. [Jobs](#jobs)
8. [Middleware](#middleware)
9. [Seeders](#seeders)
10. [Configuration](#configuration)
11. [Third-party Packages](#third-party-packages)

---

## Project Structure

```
errandly/backend/
├── app/
│   ├── Events/               # Broadcast events (Pusher)
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Api/          # Customer, runner, shared endpoints
│   │   │   └── Admin/        # Admin-only endpoints
│   │   └── Middleware/       # Custom middleware
│   ├── Jobs/                 # Queue jobs
│   ├── Models/               # Eloquent models
│   └── Services/             # Business logic layer
├── config/
│   └── errandly.php          # Platform-specific config
├── database/
│   ├── migrations/           # 5 migration files (ordered)
│   └── seeders/              # 5 seeders
└── routes/
    └── api.php               # All API routes
```

---

## Models

### `User`
The central identity model. Users can be customers, runners, or admins (via Spatie roles).

**Key columns:** `first_name`, `last_name`, `email`, `phone`, `status` (active/pending/suspended/blacklisted), `kyc_status` (pending/submitted/approved/rejected), `is_online`, `device_token`, `device_type`, `referral_code`, `emergency_contact_name/phone`, `latitude`, `longitude`, `suspended_at`, `suspended_until`.

**Relationships:**
- `hasOne` → RunnerProfile
- `hasOne` → Wallet
- `hasMany` → Errand (as customer)
- `hasMany` → Errand (as runner)
- `hasMany` → Message
- `hasMany` → AppNotification

---

### `RunnerProfile`
Extends `User` for runner-specific data.

**Key columns:** `nin`, `bank_name`, `bank_account_number`, `bank_code`, `transport_type` (foot/bicycle/motorcycle/car), `service_radius_km`, `is_available`, `is_online`, `is_verified`, `verification_status`, `trust_score` (starts at 70.00), `completion_rate`, `total_errands`, `cancelled_errands`, `average_rating`, `total_earnings`, `current_latitude`, `current_longitude`, `background_check_status`, `next_of_kin_*`, `guarantor_*`, `available_days`, `available_hours_start/end`.

---

### `Errand`
Core transaction model.

**Status enum:** `draft`, `posted`, `pending_assignment`, `accepted`, `runner_en_route`, `item_picked`, `in_progress`, `awaiting_confirmation`, `completed`, `cancelled`, `failed`, `disputed`, `refunded`.

**Urgency enum:** `standard`, `urgent`, `scheduled`.

**Category enum:** `package_pickup`, `item_delivery`, `grocery_purchase`, `queue_standing`, `document_submission`, `document_collection`, `shopping_assistance`, `prescription_pickup`, `personal_assistance`, `custom_errand`.

**Payment status enum:** `pending_funding`, `funded`, `in_escrow`, `released`, `refunded`, `frozen`.

**Key columns:** `customer_id`, `runner_id`, `title`, `description`, `category`, `urgency`, `pickup_address/latitude/longitude/city`, `destination_address/latitude/longitude/city`, `budget`, `platform_fee`, `runner_earnings`, `pickup_otp`, `delivery_otp`, `pickup_otp_verified_at`, `delivery_otp_verified_at`, `panic_triggered_at`, `panic_triggered_by`, `escrow_id`, `cancellation_by`, `cancellation_reason`, `is_recurring`, `scheduled_at`, `attachments`.

**Indexes:** `(status, created_at)`, `(customer_id, status)`, `(runner_id, status)`, `(pickup_latitude, pickup_longitude)`.

---

### `Wallet`
One wallet per user. All monetary values are stored in kobo (integer, smallest unit of NGN).

**Key columns:** `balance`, `escrow_balance`, `pending_withdrawal`, `currency` (NGN), `is_frozen`, `frozen_reason`, `frozen_at`, `total_funded`, `total_withdrawn`, `total_earned`.

**Methods:** `credit()`, `debit()`, `hasSufficientFunds()`.

---

### `EscrowTransaction`
Represents a single escrow hold for an errand.

**Status enum:** `pending_funding`, `funded`, `in_escrow`, `released`, `refunded`, `frozen`.

**Key columns:** `errand_id`, `customer_id`, `runner_id`, `total_amount`, `runner_amount`, `platform_fee`, `funded_at`, `released_at`, `refunded_at`, `frozen_at`, `frozen_reason`, `release_reason`, `refund_reason`, `payment_reference`, `gateway_response`.

**Methods:** `canRelease()`, `canRefund()`.

---

### `WalletTransaction`
Ledger record for every credit/debit.

**Type enum:** `funding`, `errand_payment`, `earnings`, `refund`, `withdrawal`, `commission`, `bonus`, `tip`, `freeze`.

**Direction enum:** `credit`, `debit`.

**Key columns:** `wallet_id`, `type`, `direction`, `amount`, `description`, `reference` (polymorphic), `balance_after`, `status`, `metadata`.

---

### `KycDocument`
One KYC record per user. Updated on resubmission.

**Status enum:** `pending`, `submitted`, `under_review`, `approved`, `rejected`, `resubmission_required`.

**Type enum:** `customer`, `runner`.

**ID type enum:** `national_id`, `drivers_license`, `passport`, `voters_card`.

**Key columns:** `id_number`, `id_document_url`, `selfie_url`, `live_photo_url`, `address_proof_url`, `utility_bill_url`, `nin_number`, `bvn_number`, `face_match_score`, `liveness_score`, `document_confidence`, `rejection_reason`, `resubmission_reason`, `reviewed_by`, `reviewed_at`.

---

### `Dispute`
Raised by either customer or runner against an errand.

**Type enum:** `item_not_delivered`, `item_damaged`, `wrong_task_execution`, `harassment`, `fraudulent_completion`, `missing_payment`, `other`.

**Status enum:** `open`, `under_review`, `awaiting_evidence`, `resolved`, `closed`.

**Resolution type enum:** `refund`, `release`, `partial_refund`, `no_action`.

**Key columns:** `errand_id`, `raised_by`, `assigned_to`, `description`, `resolution`, `resolution_type`, `refund_amount`, `penalty_applied`, `evidence` (JSON), `resolved_at`, `closed_at`, `closing_notes`.

---

### `DisputeEvidence`
Structured evidence attached to disputes.

**Type enum:** `photo`, `video`, `document`, `text`.

**Key columns:** `dispute_id`, `submitted_by`, `type`, `url`, `description`.

---

### `DisputeMessage`
In-dispute messaging between parties and admin.

---

### `Rating`
Bidirectional rating after errand completion.

**Role enum:** `customer_rates_runner`, `runner_rates_customer`.

**Scored dimensions (1–5 decimal):** `overall_rating`, `punctuality`, `professionalism`, `communication`, `accuracy`, `safety`, `trustworthiness`, `clarity`, `politeness`, `payment_reliability`, `honesty`.

**Unique constraint:** `(errand_id, rater_id, role)` — each party rates once per errand.

---

### `Message`
In-errand chat between customer and runner.

**Type enum:** `text`, `image`, `voice`, `system`, `location`.

**Key columns:** `errand_id`, `sender_id`, `type`, `content`, `media_url`, `media_type`, `duration_seconds`, `read_at`, `is_system`.

**Index:** `(errand_id, created_at)`.

---

### `TrackingLog`
GPS breadcrumbs for live location tracking.

**Key columns:** `errand_id`, `runner_id`, `latitude`, `longitude`, `speed`, `heading`, `accuracy`, `logged_at`.

**Index:** `(errand_id, logged_at)`.

---

### `ProofSubmission`
Evidence a runner submits when marking a task complete.

**Type enum:** `photo`, `receipt`, `signature`, `note`.

**Key columns:** `errand_id`, `runner_id`, `type`, `file_url`, `notes`, `submitted_at`, `verified_at`.

---

### `PanicEvent`
Logged when a user hits the panic button during an active errand.

**Status enum:** `active`, `responded`, `resolved`.

**Key columns:** `errand_id`, `triggered_by`, `latitude`, `longitude`, `status`, `notes`, `admin_id`, `resolved_at`, `resolution_notes`.

---

### `ErrandStatusHistory`
Full audit trail of every status transition.

**Key columns:** `errand_id`, `from_status`, `to_status`, `changed_by`, `reason`, `metadata`.

**Index:** `(errand_id, created_at)`.

---

### `SavedAddress`
Reusable addresses stored by customers.

**Key columns:** `user_id`, `label`, `address`, `city`, `state`, `latitude`, `longitude`, `is_default`.

---

### `AppNotification`
In-app notification record.

**Key columns:** `user_id`, `type`, `title`, `body`, `data` (JSON), `read_at`, `action_url`, `icon`.

**Index:** `(user_id, read_at)`.

---

## Services

### `ErrandService`

The core orchestration layer. Injected with `WalletService`, `NotificationService`, `TrustScoreService`, and `OtpService`.

| Method | Description |
|--------|-------------|
| `createErrand(User, array)` | Validates wallet balance, creates errand, locks funds in escrow atomically, dispatches `NotifyNearbyRunners` job |
| `acceptErrand(User, Errand)` | `lockForUpdate()` race-condition guard, assigns runner, notifies customer, fires `RunnerAssigned` event |
| `markArrived(User, Errand)` | Transitions to `runner_en_route`, generates pickup OTP via cache, notifies customer |
| `verifyPickupOtp(User, Errand, string)` | Validates OTP from Redis cache, transitions to `item_picked` |
| `startErrand(User, Errand)` | Transitions to `in_progress`, notifies customer |
| `submitProof(User, Errand, array)` | Creates `ProofSubmission`, transitions to `awaiting_confirmation`, generates delivery OTP |
| `confirmCompletion(User, Errand, string)` | Verifies delivery OTP, transitions to `completed`, releases escrow, updates runner stats, fires event |
| `cancelByCustomer(User, Errand, string)` | Validates cancellability, calculates tiered refund, processes refund atomically |
| `cancelByRunner(User, Errand, string)` | Resets errand to `pending_assignment`, penalizes trust score, re-dispatches runner search |
| `triggerPanic(User, Errand, array)` | Creates `PanicEvent`, transitions to `disputed`, freezes escrow, fires `PanicTriggered` event |

**Cancellation refund tiers:**

| Status at cancellation | Customer refund |
|-----------------------|-----------------|
| `posted` / `pending_assignment` | 100% |
| `accepted` | Budget only (platform fee forfeited) |
| `runner_en_route` | 50% of total |
| Any later stage | 0% |

---

### `WalletService`

Handles all financial operations. Every method uses `DB::transaction` with `lockForUpdate()` to prevent race conditions.

| Method | Description |
|--------|-------------|
| `createWalletForUser(User)` | Creates wallet on user registration |
| `fundWallet(User, int, string)` | Credits wallet from payment gateway; checks for frozen status |
| `holdForEscrow(User, int, int)` | Debits customer wallet and increments escrow_balance |
| `releaseEscrow(Errand)` | Credits runner, decrements customer escrow_balance, marks escrow released, updates runner profile earnings |
| `processRefund(User, Errand, int)` | Credits customer, decrements escrow_balance, marks escrow refunded |
| `freezeWallet(User, string, User)` | Admin action to freeze wallet |
| `unfreezeWallet(User)` | Admin action to unfreeze |
| `requestWithdrawal(User, int)` | Checks available balance (balance minus pending_withdrawal), blocks if active disputes exist |

---

### `TrustScoreService`

Calculates a runner's Trust Score using raw SQL Haversine for proximity and aggregated DB queries.

**Score formula (max 100):**
```
score = (completion_rate × 30)
      + (avg_rating / 5 × 30)
      - min(cancellations × 5, 20)   ← cancellation penalty cap
      - min(disputes × 10, 15)       ← dispute penalty cap
      + milestone_bonus
```

| Method | Description |
|--------|-------------|
| `recalculate(RunnerProfile)` | Full score recomputation; updates profile fields |
| `penalizeForCancellation(RunnerProfile)` | Immediate −5 deduction |
| `penalizeForSafetyIncident(RunnerProfile)` | Immediate −20 deduction |
| `applyManualAdjustment(RunnerProfile, float, string)` | Admin manual adjustment |
| `findNearbyEligibleRunners(float, float, float, int)` | Haversine-based geo query; filters by `is_online`, `is_available`, `approved`, no active errand; sorts by trust_score DESC then distance ASC |

---

### `OtpService`

6-digit OTP generation backed by Redis Cache.

| OTP Type | TTL | Cache key pattern |
|----------|-----|-------------------|
| Pickup | 3,600 s (1 hour) | `pickup_otp:{errand_id}` |
| Delivery | 3,600 s (1 hour) | `delivery_otp:{errand_id}` |
| Auth (phone verify) | 600 s (10 min) | `auth_otp:{phone}` |

OTPs are also bcrypt-hashed and stored on the Errand row for audit; plain value lives only in Redis.

---

### `KycService`

| Method | Description |
|--------|-------------|
| `submitCustomerKyc(User, array)` | Upserts KYC record, sets user `kyc_status = submitted` |
| `submitRunnerKyc(User, array)` | Upserts KYC, updates runner `verification_status = submitted` |
| `approveKyc(KycDocument, User, string)` | Sets user active, sets runner verified, sends approval notification |
| `rejectKyc(KycDocument, User, string)` | Sets statuses to rejected, sends rejection notification |
| `requestResubmission(KycDocument, User, string)` | Sets `resubmission_required` status, sends notification |

---

### `NotificationService`

Persists `AppNotification` records and optionally sends push notifications via Firebase/device tokens.

---

## API Controllers

### `AuthController`
| Action | Notes |
|--------|-------|
| `registerCustomer` | Creates user + wallet, sends phone OTP |
| `registerRunner` | Creates user + wallet + RunnerProfile |
| `login` | Returns Sanctum token + user with roles |
| `forgotPassword` / `resetPassword` | Standard Laravel password reset |
| `verifyPhone` / `resendOtp` | Phone verification via OtpService |
| `refresh` | Token refresh |
| `logout` | Revokes Sanctum token |
| `me` | Returns authenticated user with role, profile |
| `updateProfile` / `changePassword` | Profile management |
| `updateDeviceToken` | Stores FCM/APNS device token for push |

---

### `CustomerController`
| Action | Notes |
|--------|-------|
| `dashboard` | Summary stats: active errands, wallet balance, recent activity |
| `savedAddresses` | List saved addresses |
| `storeAddress` / `deleteAddress` | CRUD for saved addresses |

---

### `ErrandController`
| Action | Accessible by | Notes |
|--------|--------------|-------|
| `customerIndex` | Customer | Paginated list with filters |
| `store` | Customer | Calls `ErrandService::createErrand` |
| `show` | Both | Returns full errand with escrow, runner, proof |
| `update` | Customer | Allowed only in `draft` / `posted` status |
| `cancel` | Customer | Calls `ErrandService::cancelByCustomer` |
| `confirmCompletion` | Customer | Verifies delivery OTP |
| `generateDeliveryOtp` | Customer | Manual OTP regeneration |
| `panic` | Both | Calls `ErrandService::triggerPanic` |
| `getProof` | Customer | Returns proof submissions for errand |
| `available` | Runner | Nearby unassigned errands filtered by runner location |
| `runnerIndex` | Runner | Runner's own errand history |
| `accept` / `reject` | Runner | Accept/reject an available errand |
| `arrived` | Runner | Marks runner_en_route, generates pickup OTP |
| `verifyPickupOtp` | Runner | Verifies pickup OTP → item_picked |
| `start` | Runner | Transitions to in_progress |
| `complete` | Runner | Submits proof → awaiting_confirmation |
| `runnerCancel` | Runner | Cancels with trust score penalty |
| `submitProof` | Runner | Uploads proof (photo/receipt/signature) |

---

### `WalletController`
| Action | Notes |
|--------|-------|
| `show` | Wallet balance + summary |
| `transactions` | Paginated ledger |
| `fund` | Initiate Paystack/Stripe payment |
| `verifyPayment` | Confirm payment and credit wallet |
| `escrow` | List active escrow holds |

---

### `MessageController`
| Action | Notes |
|--------|-------|
| `conversations` | All conversations (grouped by errand) |
| `show` | Messages in a specific errand conversation |
| `send` | Send text/image/location message; fires `NewMessage` event |
| `sendVoice` | Upload voice note |
| `markRead` | Mark conversation read |

---

### `TrackingController`
| Action | Notes |
|--------|-------|
| `customerTrack` | Latest runner position + breadcrumbs for a customer's errand |
| `updateLocation` | Runner posts GPS coordinates; creates `TrackingLog`, fires `RunnerLocationUpdated` |

---

### `DisputeController`
| Action | Notes |
|--------|-------|
| `index` | User's disputes |
| `store` | Raise a dispute |
| `show` | Dispute detail with evidence and messages |
| `addEvidence` | Upload evidence file/text |

---

### `RatingController`
| Action | Notes |
|--------|-------|
| `store` | Submit rating; triggers trust score recalculation |
| `myRatings` | Ratings received by authenticated user |
| `given` | Ratings submitted by authenticated user |

---

### `NotificationController`
| Action | Notes |
|--------|-------|
| `index` | Paginated notifications |
| `markRead` / `markAllRead` | Mark as read |
| `destroy` | Delete notification |
| `broadcast` | Admin-only: broadcast message to all users |

---

### `KycController`
| Action | Notes |
|--------|-------|
| `status` | Current KYC status for authenticated user |
| `submit` | Customer KYC submission |
| `resubmit` | Resubmit after rejection |
| `documents` | List submitted documents |
| `submitRunnerKyc` | Runner-specific KYC (accessible without `runner.verified` middleware) |

---

### `PaymentController`
| Action | Notes |
|--------|-------|
| `initialize` | Create Paystack/Stripe session |
| `verify` | Verify payment and credit wallet |
| `stripeWebhook` | Webhook handler (no auth) |
| `paystackWebhook` | Webhook handler (no auth) |

---

## Admin Controllers

### `AdminDashboardController`
| Action | Notes |
|--------|-------|
| `index` | Platform metrics: total users, runners, errands, revenue, dispute rates |
| `metrics` | Time-series revenue, errand volume |
| `liveMap` | Active runner positions for real-time admin map |

---

### `AdminUserController`
| Action | Notes |
|--------|-------|
| `index` | Paginated user list with filters |
| `show` | Full user detail with wallet, errands, KYC |
| `suspend` / `restore` | User suspension management |
| `blacklist` | Permanent ban |
| `verify` | Manual verification |
| `destroy` | Soft delete |

---

### `AdminRunnerController`
| Action | Notes |
|--------|-------|
| `index` | All runners with KYC and trust score |
| `show` | Runner detail |
| `approve` | Approve runner (sets verified) |
| `suspend` | Suspend runner |
| `adjustTrustScore` | Manual trust score override |

---

### `AdminKycController`
| Action | Notes |
|--------|-------|
| `index` | All KYC submissions |
| `pending` | Pending submissions only |
| `show` | Full KYC detail with documents |
| `approve` | Calls `KycService::approveKyc` |
| `reject` | Calls `KycService::rejectKyc` |
| `requestResubmission` | Calls `KycService::requestResubmission` |

---

### `AdminErrandController`
| Action | Notes |
|--------|-------|
| `index` | All errands with filters |
| `show` | Full errand detail |
| `reassign` | Force-assign a different runner |
| `cancel` | Admin cancellation |
| `timeline` | Full status history |
| `tracking` | All tracking logs |

---

### `AdminWalletController`
| Action | Notes |
|--------|-------|
| `overview` | Total platform balance, escrow, commissions |
| `escrow` | All active escrow records |
| `transactions` | All wallet transactions |
| `refund` | Force refund for an errand |
| `release` | Force release escrow |
| `freeze` / `unfreeze` | Wallet freeze control |

---

### `AdminDisputeController`
| Action | Notes |
|--------|-------|
| `index` | All disputes |
| `show` | Dispute with evidence, messages, errand |
| `assign` | Assign to staff member |
| `resolve` | Resolve with refund/release decision |
| `close` | Close without resolution |

---

### `AdminReportController`
| Action | Notes |
|--------|-------|
| `revenue` | Revenue by period |
| `errands` | Errand stats by category, city, status |
| `users` | User growth, churn |
| `incidents` | Panic events and dispute trends |
| `fraud` | Flagged accounts, suspicious patterns |
| `export` | Generate CSV/PDF export |

---

### `AdminSettingsController`
| Action | Notes |
|--------|-------|
| `index` | All platform settings (key/value store) |
| `update` | Update settings |
| `serviceAreas` | List service areas |
| `storeServiceArea` / `updateServiceArea` / `deleteServiceArea` | Service area CRUD |

---

## Events

| Event | Channel | Description |
|-------|---------|-------------|
| `ErrandStatusUpdated` | `errand.{id}` | Fired on every errand status transition |
| `RunnerAssigned` | `errand.{id}` | Fired when runner accepts an errand |
| `RunnerLocationUpdated` | `errand.{id}` | Fired when runner posts a GPS update |
| `NewMessage` | `errand.{id}` | Fired when a message is sent in a conversation |
| `PanicTriggered` | `admin`, `errand.{id}` | Fired when panic button is pressed |

All events implement `ShouldBroadcast` and are dispatched via Pusher Channels.

---

## Jobs

### `NotifyNearbyRunners`
- Dispatched after errand creation.
- Calls `TrustScoreService::findNearbyEligibleRunners` with Haversine SQL.
- Sends push notifications to up to 20 nearby, available, approved, idle runners.
- Filters out runners currently on an active errand.

### `AutoReassignErrand`
- Referenced in `ErrandService::cancelByRunner`.
- Re-queues errand for runner search after a cancellation.

---

## Middleware

### `RunnerVerifiedMiddleware`
Applied to all `runner.*` routes (except `verificationStatus` and `kyc/submit`).

Checks:
1. User has role `runner`
2. RunnerProfile exists
3. `verification_status === approved`
4. `is_verified === true`

Returns 403 with a message directing the runner to complete KYC if any check fails.

---

## Seeders

| Seeder | What it creates |
|--------|----------------|
| `RolesAndPermissionsSeeder` | Spatie roles: `customer`, `runner`, `admin`, `verification_officer` |
| `SettingsSeeder` | Default platform settings in the `settings` table |
| `ServiceAreaSeeder` | 5 Uyo service areas: Uyo City Centre, Ewet Housing, Use Offot, Ikot Ekpene Road, Ring Road |
| `AdminUserSeeder` | Admin account + KYC officer account |
| `TestUsersSeeder` | Sample customer and runner accounts for development |
| `DatabaseSeeder` | Orchestrates all seeders in correct order |

---

## Configuration

### `config/errandly.php`

```php
[
    'commission_rate'                   => 0.15,          // 15%
    'min_errand_amount'                 => 500,           // ₦500
    'currency'                          => 'NGN',
    'max_runner_radius_km'              => 15,
    'errand_acceptance_timeout_minutes' => 30,
    'min_withdrawal_amount'             => 1000,          // ₦1,000
    'withdrawal_processing_days'        => 1,
    'otp_expiry_seconds'                => 3600,          // 1 hour
]
```

---

## Third-party Packages

| Package | Purpose |
|---------|---------|
| `laravel/sanctum` | API token authentication |
| `tymon/jwt-auth` | JWT token support |
| `spatie/laravel-permission` | Role-based access control |
| `spatie/laravel-media-library` | File/media management |
| `spatie/laravel-query-builder` | Filterable, sortable API queries |
| `spatie/laravel-activitylog` | Audit log |
| `laravel/horizon` | Redis queue monitoring dashboard |
| `laravel/telescope` | Request/query debugging dashboard |
| `pusher/pusher-php-server` | Pusher Channels broadcasting |
| `twilio/sdk` | SMS OTP delivery |
| `stripe/stripe-php` | Stripe payment processing |
| `intervention/image` | Image resizing/processing |
| `maatwebsite/excel` | Excel export for admin reports |
| `barryvdh/laravel-dompdf` | PDF export for admin reports |
| `league/flysystem-aws-s3-v3` | AWS S3 file storage |
| `predis/predis` | Redis client |
