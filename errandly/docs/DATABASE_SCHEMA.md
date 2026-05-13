# Errandly — Database Schema

PostgreSQL 15+ database. All monetary values are stored as integers in **kobo** (1 NGN = 100 kobo). All timestamps are UTC.

---

## Table of Contents

1. [Entity Relationship Overview](#entity-relationship-overview)
2. [Table: users](#table-users)
3. [Table: runner_profiles](#table-runner_profiles)
4. [Table: errands](#table-errands)
5. [Table: wallets](#table-wallets)
6. [Table: escrow_transactions](#table-escrow_transactions)
7. [Table: wallet_transactions](#table-wallet_transactions)
8. [Table: kyc_documents](#table-kyc_documents)
9. [Table: messages](#table-messages)
10. [Table: tracking_logs](#table-tracking_logs)
11. [Table: proof_submissions](#table-proof_submissions)
12. [Table: ratings](#table-ratings)
13. [Table: disputes](#table-disputes)
14. [Table: dispute_evidence](#table-dispute_evidence)
15. [Table: panic_events](#table-panic_events)
16. [Table: errand_status_history](#table-errand_status_history)
17. [Table: saved_addresses](#table-saved_addresses)
18. [Table: app_notifications](#table-app_notifications)
19. [Table: settings](#table-settings)
20. [Table: service_areas](#table-service_areas)
21. [Table: roles & permissions (Spatie)](#table-roles--permissions-spatie)
22. [Migration Execution Order](#migration-execution-order)

---

## Entity Relationship Overview

```
users
 ├── runner_profiles     (1:1)
 ├── wallets             (1:1)
 ├── kyc_documents       (1:1)
 ├── saved_addresses     (1:N)
 ├── app_notifications   (1:N)
 ├── errands             (1:N, as customer)
 ├── errands             (1:N, as runner)
 ├── messages            (1:N, as sender)
 ├── ratings             (1:N, as rater)
 ├── ratings             (1:N, as rated)
 ├── disputes            (1:N, as raised_by)
 ├── disputes            (1:N, as assigned_to)
 └── panic_events        (1:N, as triggered_by)

errands
 ├── escrow_transactions (1:1)
 ├── messages            (1:N)
 ├── tracking_logs       (1:N)
 ├── proof_submissions   (1:N)
 ├── ratings             (1:N)
 ├── disputes            (1:N)
 ├── errand_status_history (1:N)
 └── panic_events        (1:N)

disputes
 └── dispute_evidence    (1:N)

wallets
 └── wallet_transactions (1:N)
```

---

## Table: `users`

Central identity table. All platform participants (customers, runners, admins) are users.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `first_name` | varchar | No | | |
| `last_name` | varchar | No | | |
| `email` | varchar (unique) | No | | |
| `phone` | varchar (unique) | No | | |
| `password` | varchar | No | | bcrypt hash |
| `email_verified_at` | timestamp | Yes | null | |
| `phone_verified_at` | timestamp | Yes | null | |
| `profile_image` | varchar | Yes | null | |
| `date_of_birth` | date | Yes | null | |
| `gender` | enum | Yes | null | male, female, other |
| `address` | text | Yes | null | |
| `city` | varchar | Yes | null | |
| `state` | varchar | Yes | null | |
| `country` | varchar | No | 'Nigeria' | |
| `latitude` | decimal(10,8) | Yes | null | |
| `longitude` | decimal(11,8) | Yes | null | |
| `emergency_contact_name` | varchar | Yes | null | |
| `emergency_contact_phone` | varchar | Yes | null | |
| `referral_code` | varchar (unique) | Yes | null | |
| `referred_by` | bigint (FK→users) | Yes | null | |
| `status` | enum | No | 'pending' | active, pending, suspended, blacklisted |
| `kyc_status` | enum | No | 'pending' | pending, submitted, approved, rejected |
| `is_online` | boolean | No | false | |
| `last_seen_at` | timestamp | Yes | null | |
| `device_token` | varchar | Yes | null | FCM/APNS token |
| `device_type` | enum | Yes | null | ios, android, web |
| `suspension_reason` | text | Yes | null | |
| `suspended_at` | timestamp | Yes | null | |
| `suspended_until` | timestamp | Yes | null | null = indefinite |
| `remember_token` | varchar | Yes | null | |
| `deleted_at` | timestamp | Yes | null | soft delete |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `runner_profiles`

Extended attributes for runner users. One-to-one with `users`.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `user_id` | bigint (FK→users) | No | | |
| `nin` | varchar | Yes | null | National ID number |
| `bank_name` | varchar | Yes | null | |
| `bank_account_number` | varchar | Yes | null | |
| `bank_account_name` | varchar | Yes | null | |
| `bank_code` | varchar | Yes | null | CBN bank code |
| `next_of_kin_name` | varchar | Yes | null | |
| `next_of_kin_phone` | varchar | Yes | null | |
| `next_of_kin_relationship` | varchar | Yes | null | |
| `guarantor_name` | varchar | Yes | null | |
| `guarantor_phone` | varchar | Yes | null | |
| `guarantor_address` | text | Yes | null | |
| `transport_type` | enum | No | 'foot' | foot, bicycle, motorcycle, car |
| `service_radius_km` | integer | No | 10 | Max km from location |
| `service_city` | varchar | Yes | null | |
| `service_state` | varchar | Yes | null | |
| `skills` | json | Yes | null | Array of skill tags |
| `available_days` | json | Yes | null | Array: ["Mon","Tue",...] |
| `available_hours_start` | time | No | '08:00:00' | |
| `available_hours_end` | time | No | '20:00:00' | |
| `is_available` | boolean | No | false | Currently taking errands |
| `is_online` | boolean | No | false | App is open and active |
| `is_verified` | boolean | No | false | KYC approved |
| `verification_status` | enum | No | 'pending' | pending, submitted, approved, rejected |
| `verified_at` | timestamp | Yes | null | |
| `trust_score` | decimal(5,2) | No | 70.00 | 0–100 |
| `completion_rate` | decimal(5,2) | No | 100.00 | Percentage |
| `total_errands` | integer | No | 0 | Completed count |
| `cancelled_errands` | integer | No | 0 | Runner-initiated cancellations |
| `average_rating` | decimal(3,2) | No | 0.00 | |
| `total_earnings` | bigint | No | 0 | Lifetime earnings in kobo |
| `current_latitude` | decimal(10,8) | Yes | null | Last known position |
| `current_longitude` | decimal(11,8) | Yes | null | |
| `location_updated_at` | timestamp | Yes | null | |
| `background_check_status` | enum | No | 'pending' | pending, cleared, failed |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `errands`

Core transactional table. Represents each errand from creation to completion.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `customer_id` | bigint (FK→users) | No | | Cascade delete |
| `runner_id` | bigint (FK→users) | Yes | null | Null until accepted |
| `title` | varchar | No | | |
| `description` | text | No | | |
| `category` | enum | No | | package_pickup, item_delivery, grocery_purchase, queue_standing, document_submission, document_collection, shopping_assistance, prescription_pickup, personal_assistance, custom_errand |
| `status` | enum | No | 'draft' | draft, posted, pending_assignment, accepted, runner_en_route, item_picked, in_progress, awaiting_confirmation, completed, cancelled, failed, disputed, refunded |
| `urgency` | enum | No | 'standard' | standard, urgent, scheduled |
| `pickup_address` | text | No | | |
| `pickup_latitude` | decimal(10,8) | No | | |
| `pickup_longitude` | decimal(11,8) | No | | |
| `pickup_city` | varchar | Yes | null | |
| `destination_address` | text | No | | |
| `destination_latitude` | decimal(10,8) | No | | |
| `destination_longitude` | decimal(11,8) | No | | |
| `destination_city` | varchar | Yes | null | |
| `recipient_name` | varchar | Yes | null | |
| `recipient_phone` | varchar | Yes | null | |
| `item_details` | text | Yes | null | |
| `special_instructions` | text | Yes | null | |
| `budget` | bigint | No | | Runner payout in kobo |
| `platform_fee` | bigint | No | 0 | 15% of budget |
| `runner_earnings` | bigint | No | 0 | Same as budget |
| `scheduled_at` | timestamp | Yes | null | For scheduled urgency |
| `accepted_at` | timestamp | Yes | null | |
| `started_at` | timestamp | Yes | null | |
| `completed_at` | timestamp | Yes | null | |
| `cancelled_at` | timestamp | Yes | null | |
| `failed_at` | timestamp | Yes | null | |
| `cancellation_reason` | text | Yes | null | |
| `cancellation_by` | enum | Yes | null | customer, runner, admin |
| `failure_reason` | text | Yes | null | |
| `pickup_otp` | varchar | Yes | null | bcrypt hash |
| `pickup_otp_verified_at` | timestamp | Yes | null | |
| `delivery_otp` | varchar | Yes | null | bcrypt hash |
| `delivery_otp_verified_at` | timestamp | Yes | null | |
| `is_recurring` | boolean | No | false | |
| `recurring_schedule` | json | Yes | null | Cron-like schedule |
| `panic_triggered_at` | timestamp | Yes | null | |
| `panic_triggered_by` | bigint (FK→users) | Yes | null | |
| `payment_status` | enum | No | 'pending_funding' | pending_funding, funded, in_escrow, released, refunded, frozen |
| `escrow_id` | bigint (FK→escrow_transactions) | Yes | null | |
| `attachments` | json | Yes | null | Array of S3 URLs |
| `estimated_duration_minutes` | integer | Yes | null | |
| `deleted_at` | timestamp | Yes | null | Soft delete |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

**Indexes:**
- `(status, created_at)` — listing by status
- `(customer_id, status)` — customer errand list
- `(runner_id, status)` — runner errand list
- `(pickup_latitude, pickup_longitude)` — geo proximity queries

---

## Table: `wallets`

One wallet per user. Balances stored as kobo integers.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `user_id` | bigint (FK→users, unique) | No | | |
| `balance` | bigint | No | 0 | Available balance in kobo |
| `escrow_balance` | bigint | No | 0 | Amount locked in escrow |
| `pending_withdrawal` | bigint | No | 0 | Withdrawal requested, not processed |
| `currency` | char(3) | No | 'NGN' | |
| `is_frozen` | boolean | No | false | |
| `frozen_reason` | text | Yes | null | |
| `frozen_at` | timestamp | Yes | null | |
| `total_funded` | bigint | No | 0 | Lifetime top-ups |
| `total_withdrawn` | bigint | No | 0 | Lifetime withdrawals |
| `total_earned` | bigint | No | 0 | Lifetime earnings (runners) |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `escrow_transactions`

Single escrow record per errand. Tracks the full lifecycle of held funds.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `errand_id` | bigint (FK→errands) | No | | |
| `customer_id` | bigint (FK→users) | No | | |
| `runner_id` | bigint (FK→users) | Yes | null | Set on acceptance |
| `total_amount` | bigint | No | | budget + platform_fee |
| `runner_amount` | bigint | No | | budget only |
| `platform_fee` | bigint | No | | 15% of budget |
| `status` | enum | No | 'pending_funding' | pending_funding, funded, in_escrow, released, refunded, frozen |
| `funded_at` | timestamp | Yes | null | |
| `released_at` | timestamp | Yes | null | When runner was paid |
| `refunded_at` | timestamp | Yes | null | |
| `frozen_at` | timestamp | Yes | null | Panic/dispute freeze |
| `frozen_reason` | text | Yes | null | |
| `release_reason` | text | Yes | null | |
| `refund_reason` | text | Yes | null | |
| `payment_method` | varchar | Yes | null | wallet, paystack, stripe |
| `payment_reference` | varchar | Yes | null | Gateway reference |
| `gateway_response` | json | Yes | null | Raw gateway data |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `wallet_transactions`

Immutable ledger of every financial movement.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `wallet_id` | bigint (FK→wallets) | No | | |
| `type` | enum | No | | funding, errand_payment, earnings, refund, withdrawal, commission, bonus, tip, freeze |
| `direction` | enum | No | | credit, debit |
| `amount` | bigint | No | | In kobo |
| `description` | text | No | | Human-readable description |
| `reference_type` | varchar | Yes | null | Polymorphic: e.g. "App\Models\Errand" |
| `reference_id` | bigint | Yes | null | Related record ID |
| `balance_after` | bigint | No | | Wallet balance after this transaction |
| `status` | enum | No | 'completed' | pending, completed, failed |
| `metadata` | json | Yes | null | Extra context |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

**Indexes:**
- `(wallet_id, created_at)` — transaction history
- `(type, direction)` — financial reporting

---

## Table: `kyc_documents`

One record per user (upserted on resubmission).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `user_id` | bigint (FK→users, unique) | No | | |
| `reviewed_by` | bigint (FK→users) | Yes | null | Admin/officer who reviewed |
| `type` | enum | No | | customer, runner |
| `status` | enum | No | 'pending' | pending, submitted, under_review, approved, rejected, resubmission_required |
| `id_type` | enum | Yes | null | national_id, drivers_license, passport, voters_card |
| `id_number` | varchar | Yes | null | |
| `id_document_url` | text | Yes | null | S3 URL |
| `selfie_url` | text | Yes | null | S3 URL |
| `live_photo_url` | text | Yes | null | S3 URL |
| `address_proof_url` | text | Yes | null | S3 URL |
| `utility_bill_url` | text | Yes | null | S3 URL |
| `nin_number` | varchar | Yes | null | |
| `bvn_number` | varchar | Yes | null | |
| `submitted_at` | timestamp | Yes | null | |
| `reviewed_at` | timestamp | Yes | null | |
| `rejection_reason` | text | Yes | null | |
| `resubmission_reason` | text | Yes | null | |
| `notes` | text | Yes | null | Internal reviewer notes |
| `face_match_score` | decimal(5,2) | Yes | null | AI face match 0–100 |
| `liveness_score` | decimal(5,2) | Yes | null | AI liveness 0–100 |
| `document_confidence` | decimal(5,2) | Yes | null | AI document confidence |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `messages`

In-errand chat messages between customer and runner.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `errand_id` | bigint (FK→errands) | No | | |
| `sender_id` | bigint (FK→users) | No | | |
| `type` | enum | No | 'text' | text, image, voice, system, location |
| `content` | text | Yes | null | For text/system messages |
| `media_url` | text | Yes | null | S3 URL for image/voice |
| `media_type` | varchar | Yes | null | MIME type |
| `duration_seconds` | integer | Yes | null | Voice note duration |
| `read_at` | timestamp | Yes | null | |
| `is_system` | boolean | No | false | Auto-generated messages |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

**Indexes:** `(errand_id, created_at)`

---

## Table: `tracking_logs`

GPS breadcrumb trail from runner during active errands.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `errand_id` | bigint (FK→errands) | No | | |
| `runner_id` | bigint (FK→users) | No | | |
| `latitude` | decimal(10,8) | No | | |
| `longitude` | decimal(11,8) | No | | |
| `speed` | decimal(5,2) | Yes | null | km/h |
| `heading` | decimal(5,2) | Yes | null | Degrees 0–360 |
| `accuracy` | decimal(8,2) | Yes | null | Metres |
| `logged_at` | timestamp | No | | GPS timestamp |

**Indexes:** `(errand_id, logged_at)`

> Note: No `timestamps()` — only `logged_at` (intentional, keeps the table lean).

---

## Table: `proof_submissions`

Evidence that a runner submits when marking a task as complete.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `errand_id` | bigint (FK→errands) | No | | |
| `runner_id` | bigint (FK→users) | No | | |
| `type` | enum | No | | photo, receipt, signature, note |
| `file_url` | text | Yes | null | S3 URL |
| `notes` | text | Yes | null | |
| `submitted_at` | timestamp | No | | |
| `verified_at` | timestamp | Yes | null | Admin verification |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `ratings`

Bidirectional post-completion ratings.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `errand_id` | bigint (FK→errands) | No | | |
| `rater_id` | bigint (FK→users) | No | | Who submitted |
| `rated_id` | bigint (FK→users) | No | | Who is being rated |
| `role` | enum | No | | customer_rates_runner, runner_rates_customer |
| `overall_rating` | decimal(3,2) | No | | 1.00–5.00 |
| `punctuality` | decimal(3,2) | Yes | null | Runner-specific |
| `professionalism` | decimal(3,2) | Yes | null | Runner-specific |
| `communication` | decimal(3,2) | Yes | null | Both |
| `accuracy` | decimal(3,2) | Yes | null | Runner-specific |
| `safety` | decimal(3,2) | Yes | null | Runner-specific |
| `trustworthiness` | decimal(3,2) | Yes | null | Runner-specific |
| `clarity` | decimal(3,2) | Yes | null | Customer-specific (errand clarity) |
| `politeness` | decimal(3,2) | Yes | null | Customer-specific |
| `payment_reliability` | decimal(3,2) | Yes | null | Customer-specific |
| `honesty` | decimal(3,2) | Yes | null | Both |
| `comment` | text | Yes | null | |
| `is_anonymous` | boolean | No | false | |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

**Unique constraint:** `(errand_id, rater_id, role)` — one rating per direction per errand.

**Indexes:** `(rated_id, role)` — for average rating queries.

---

## Table: `disputes`

Formal complaints raised against an errand.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `errand_id` | bigint (FK→errands) | No | | |
| `raised_by` | bigint (FK→users) | No | | Customer or runner |
| `assigned_to` | bigint (FK→users) | Yes | null | Admin/officer handling |
| `type` | enum | No | | item_not_delivered, item_damaged, wrong_task_execution, harassment, fraudulent_completion, missing_payment, other |
| `status` | enum | No | 'open' | open, under_review, awaiting_evidence, resolved, closed |
| `description` | text | No | | |
| `resolution` | text | Yes | null | Admin explanation |
| `resolution_type` | enum | Yes | null | refund, release, partial_refund, no_action |
| `resolved_at` | timestamp | Yes | null | |
| `refund_amount` | bigint | Yes | null | Kobo |
| `penalty_applied` | boolean | No | false | Trust score penalized |
| `evidence` | json | Yes | null | Legacy/quick evidence array |
| `closed_at` | timestamp | Yes | null | |
| `closing_notes` | text | Yes | null | |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `dispute_evidence`

Structured evidence records attached to a dispute.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `dispute_id` | bigint (FK→disputes) | No | | |
| `submitted_by` | bigint (FK→users) | No | | |
| `type` | enum | No | | photo, video, document, text |
| `url` | text | Yes | null | S3 URL for media types |
| `description` | text | Yes | null | |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `panic_events`

Records every panic button press.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `errand_id` | bigint (FK→errands) | No | | |
| `triggered_by` | bigint (FK→users) | No | | Customer or runner |
| `latitude` | decimal(10,8) | Yes | null | Location at panic time |
| `longitude` | decimal(11,8) | Yes | null | |
| `status` | enum | No | 'active' | active, responded, resolved |
| `notes` | text | Yes | null | User-provided context |
| `admin_id` | bigint (FK→users) | Yes | null | Responding admin |
| `resolved_at` | timestamp | Yes | null | |
| `resolution_notes` | text | Yes | null | |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `errand_status_history`

Immutable audit log of every errand state transition.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `errand_id` | bigint (FK→errands) | No | | |
| `from_status` | varchar | Yes | null | Null for initial status |
| `to_status` | varchar | No | | |
| `changed_by` | bigint (FK→users) | No | | Actor who caused change |
| `reason` | text | Yes | null | For cancellations etc. |
| `metadata` | json | Yes | null | Extra context |
| `created_at` | timestamp | No | | Only created_at, no updated_at |

**Indexes:** `(errand_id, created_at)`

---

## Table: `saved_addresses`

Reusable addresses saved by customers.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `user_id` | bigint (FK→users) | No | | |
| `label` | varchar | No | | "Home", "Office", etc. |
| `address` | text | No | | |
| `city` | varchar | Yes | null | |
| `state` | varchar | Yes | null | |
| `latitude` | decimal(10,8) | Yes | null | |
| `longitude` | decimal(11,8) | Yes | null | |
| `is_default` | boolean | No | false | |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `app_notifications`

In-app notification store (separate from push notifications).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `user_id` | bigint (FK→users) | No | | |
| `type` | varchar | No | | Notification type constant |
| `title` | varchar | No | | |
| `body` | text | No | | |
| `data` | json | Yes | null | Action payload |
| `read_at` | timestamp | Yes | null | Null = unread |
| `action_url` | varchar | Yes | null | Deep link |
| `icon` | varchar | Yes | null | Icon identifier |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

**Indexes:** `(user_id, read_at)` — unread count query

**Notification type constants:**
- `errand_assigned` — runner assigned
- `runner_arrived` — runner at pickup
- `task_started` — errand in progress
- `task_completed` — runner submitted proof
- `payment_released` — earnings paid
- `kyc_approved` — KYC success
- `kyc_rejected` — KYC failure
- `panic_triggered` — emergency alert

---

## Table: `settings`

Key/value platform configuration store.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `key` | varchar (unique) | No | | Setting identifier |
| `value` | text | No | | Setting value |
| `type` | varchar | No | 'string' | string, integer, float, boolean, json |
| `group` | varchar | No | 'general' | Grouping (general, payments, etc.) |
| `description` | text | Yes | null | |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

---

## Table: `service_areas`

Geographical zones where Errandly operates.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint (PK) | No | auto | |
| `name` | varchar | No | | e.g. "Uyo City Centre" |
| `city` | varchar | No | | |
| `state` | varchar | No | | e.g. "Akwa Ibom" |
| `country` | varchar | No | 'Nigeria' | |
| `center_latitude` | decimal(10,8) | Yes | null | |
| `center_longitude` | decimal(11,8) | Yes | null | |
| `radius_km` | integer | No | 10 | Coverage radius |
| `is_active` | boolean | No | true | |
| `created_at` | timestamp | No | | |
| `updated_at` | timestamp | No | | |

**Seeded areas (Uyo, Akwa Ibom):** Uyo City Centre, Ewet Housing, Use Offot, Ikot Ekpene Road, Ring Road

---

## Table: Roles & Permissions (Spatie)

Managed by `spatie/laravel-permission`. Tables: `roles`, `permissions`, `model_has_roles`, `model_has_permissions`, `role_has_permissions`.

**Seeded roles:**

| Role | Description |
|------|-------------|
| `customer` | Platform customers who post errands |
| `runner` | Verified errand runners |
| `admin` | Full platform administration |
| `verification_officer` | KYC review and runner approval only |

---

## Migration Execution Order

| Order | File | Tables Created |
|-------|------|---------------|
| 1 | `000001_create_users_table` | `users`, `password_reset_tokens`, `sessions` |
| 2 | `000002_create_runner_profiles_table` | `runner_profiles` |
| 3 | `000003_create_errands_table` | `errands` |
| 4 | `000004_create_wallets_and_transactions_table` | `wallets`, `escrow_transactions`, `wallet_transactions` |
| 5 | `000005_create_kyc_and_supporting_tables` | `kyc_documents`, `messages`, `tracking_logs`, `proof_submissions`, `ratings`, `disputes`, `dispute_evidence`, `panic_events`, `errand_status_history`, `saved_addresses`, `app_notifications`, `settings`, `service_areas` |
| + | Spatie migrations (auto) | `roles`, `permissions`, `model_has_roles`, etc. |
