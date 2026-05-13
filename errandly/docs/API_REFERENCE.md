# Errandly — API Reference

Base URL: `{APP_URL}/api`

All authenticated endpoints require: `Authorization: Bearer {token}`

---

## Authentication

### Public Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/auth/register/customer` | Register new customer |
| `POST` | `/auth/register/runner` | Register new runner |
| `POST` | `/auth/login` | Login (returns token) |
| `POST` | `/auth/forgot-password` | Send password reset email |
| `POST` | `/auth/reset-password` | Reset password with token |
| `POST` | `/auth/verify-phone` | Verify phone with OTP |
| `POST` | `/auth/resend-otp` | Resend phone verification OTP |
| `POST` | `/auth/refresh` | Refresh auth token |

### Authenticated Auth Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/auth/logout` | Logout (revoke token) |
| `GET` | `/auth/me` | Get authenticated user profile |
| `PUT` | `/auth/profile` | Update profile |
| `PUT` | `/auth/password` | Change password |
| `POST` | `/auth/device-token` | Update FCM/APNS device token |

**Register Customer body:**
```json
{
  "first_name": "string",
  "last_name": "string",
  "email": "string",
  "phone": "string",
  "password": "string",
  "password_confirmation": "string",
  "referral_code": "string (optional)"
}
```

**Register Runner body:**
```json
{
  "first_name": "string",
  "last_name": "string",
  "email": "string",
  "phone": "string",
  "password": "string",
  "password_confirmation": "string",
  "nin": "string",
  "transport_type": "foot|bicycle|motorcycle|car",
  "service_city": "string",
  "guarantor_name": "string",
  "guarantor_phone": "string",
  "guarantor_address": "string",
  "next_of_kin_name": "string",
  "next_of_kin_phone": "string"
}
```

**Login body:**
```json
{
  "email": "string",
  "password": "string",
  "device_token": "string (optional)",
  "device_type": "ios|android|web (optional)"
}
```

**Login response:**
```json
{
  "token": "string",
  "token_type": "Bearer",
  "user": { ... },
  "roles": ["customer"]
}
```

---

## KYC

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/kyc` | Any | Get current KYC status |
| `POST` | `/kyc/submit` | Any | Submit KYC documents |
| `POST` | `/kyc/resubmit` | Any | Resubmit after rejection |
| `GET` | `/kyc/documents` | Any | List submitted documents |
| `POST` | `/runner/kyc/submit` | Runner | Runner-specific KYC (pre-verification) |

**Submit KYC body (runner):**
```json
{
  "id_type": "national_id|drivers_license|passport|voters_card",
  "id_number": "string",
  "id_document_url": "string (S3 URL)",
  "selfie_url": "string",
  "live_photo_url": "string",
  "address_proof_url": "string",
  "nin_number": "string",
  "bvn_number": "string"
}
```

---

## Notifications

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/notifications` | Any | List notifications (paginated) |
| `PUT` | `/notifications/{id}/read` | Any | Mark one as read |
| `PUT` | `/notifications/read-all` | Any | Mark all as read |
| `DELETE` | `/notifications/{id}` | Any | Delete notification |

---

## Wallet

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/wallet` | Any | Wallet balance and summary |
| `GET` | `/wallet/transactions` | Any | Paginated transaction ledger |
| `POST` | `/wallet/fund` | Any | Initialize payment (Paystack/Stripe) |
| `POST` | `/wallet/verify-payment` | Any | Verify payment and credit wallet |
| `GET` | `/wallet/escrow` | Any | Active escrow holds |

**Fund wallet body:**
```json
{
  "amount": 5000,
  "gateway": "paystack|stripe"
}
```

**Verify payment body:**
```json
{
  "reference": "string"
}
```

---

## Messages

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/messages/conversations` | Any | All conversations |
| `GET` | `/messages/conversations/{errandId}` | Any | Messages in a conversation |
| `POST` | `/messages/conversations/{errandId}` | Any | Send message |
| `POST` | `/messages/conversations/{errandId}/voice` | Any | Send voice note |
| `PUT` | `/messages/conversations/{errandId}/read` | Any | Mark conversation as read |

**Send message body:**
```json
{
  "type": "text|image|location",
  "content": "string (for text)",
  "media_url": "string (for image)",
  "latitude": "number (for location)",
  "longitude": "number (for location)"
}
```

---

## Ratings

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/ratings` | Any | Submit a rating |
| `GET` | `/ratings/my-ratings` | Any | Ratings received |
| `GET` | `/ratings/given` | Any | Ratings I submitted |

**Submit rating body:**
```json
{
  "errand_id": 1,
  "overall_rating": 4.5,
  "punctuality": 5.0,
  "professionalism": 4.0,
  "communication": 4.5,
  "comment": "string (optional)",
  "is_anonymous": false
}
```

---

## Disputes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/disputes` | Any | My disputes |
| `POST` | `/disputes` | Any | Raise a dispute |
| `GET` | `/disputes/{id}` | Any | Dispute detail |
| `POST` | `/disputes/{id}/evidence` | Any | Add evidence |

**Raise dispute body:**
```json
{
  "errand_id": 1,
  "type": "item_not_delivered|item_damaged|wrong_task_execution|harassment|fraudulent_completion|missing_payment|other",
  "description": "string"
}
```

**Add evidence body:**
```json
{
  "type": "photo|video|document|text",
  "url": "string (for media types)",
  "description": "string"
}
```

---

## Customer Endpoints

> All require role: `customer`

### Errands (Customer)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/customer/errands` | List customer's errands |
| `POST` | `/customer/errands` | Create new errand |
| `GET` | `/customer/errands/{id}` | Errand detail |
| `PUT` | `/customer/errands/{id}` | Update errand (draft/posted only) |
| `POST` | `/customer/errands/{id}/cancel` | Cancel errand |
| `POST` | `/customer/errands/{id}/confirm-completion` | Confirm delivery (requires OTP) |
| `GET` | `/customer/errands/{id}/tracking` | Live runner tracking data |
| `POST` | `/customer/errands/{id}/panic` | Trigger panic button |
| `GET` | `/customer/errands/{id}/proof` | View proof submissions |
| `POST` | `/customer/errands/{id}/generate-delivery-otp` | Regenerate delivery OTP |

**Create errand body:**
```json
{
  "title": "string",
  "description": "string",
  "category": "package_pickup|item_delivery|grocery_purchase|queue_standing|document_submission|document_collection|shopping_assistance|prescription_pickup|personal_assistance|custom_errand",
  "urgency": "standard|urgent|scheduled",
  "pickup_address": "string",
  "pickup_latitude": 6.4281,
  "pickup_longitude": 3.4219,
  "pickup_city": "Lekki",
  "destination_address": "string",
  "destination_latitude": 6.4350,
  "destination_longitude": 3.4250,
  "destination_city": "Victoria Island",
  "recipient_name": "string (optional)",
  "recipient_phone": "string (optional)",
  "item_details": "string (optional)",
  "special_instructions": "string (optional)",
  "budget": 3000,
  "scheduled_at": "2024-12-01T10:00:00Z (optional)",
  "attachments": ["url1", "url2"]
}
```

**Confirm completion body:**
```json
{
  "otp": "123456"
}
```

**Panic body:**
```json
{
  "latitude": 6.4281,
  "longitude": 3.4219,
  "notes": "string (optional)"
}
```

### Customer Dashboard & Addresses

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/customer/dashboard` | Stats + active errand summary |
| `GET` | `/customer/saved-addresses` | List saved addresses |
| `POST` | `/customer/saved-addresses` | Add saved address |
| `DELETE` | `/customer/saved-addresses/{id}` | Delete saved address |

### Customer Payments

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/customer/payments/initialize` | Init Paystack/Stripe payment |
| `POST` | `/customer/payments/verify` | Verify payment reference |

---

## Runner Endpoints

> All require role: `runner` AND verified status (except verification/KYC routes)

### Runner Profile & Status

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/runner/dashboard` | Dashboard stats |
| `PUT` | `/runner/availability` | Toggle online/available |
| `PUT` | `/runner/location` | Update current GPS location |
| `GET` | `/runner/profile` | Runner profile detail |
| `PUT` | `/runner/profile` | Update profile |
| `GET` | `/runner/trust-score` | Trust score breakdown |
| `GET` | `/runner/stats` | Earnings and errand stats |
| `GET` | `/runner/verification-status` | KYC/verification status (pre-approval) |

**Update availability body:**
```json
{
  "is_online": true,
  "is_available": true
}
```

**Update location body:**
```json
{
  "latitude": 6.4281,
  "longitude": 3.4219,
  "speed": 12.5,
  "heading": 90.0,
  "accuracy": 5.0
}
```

### Errands (Runner)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/runner/errands/available` | Nearby available errands |
| `GET` | `/runner/errands/my-errands` | Runner's errand history |
| `GET` | `/runner/errands/{id}` | Errand detail |
| `POST` | `/runner/errands/{id}/accept` | Accept errand |
| `POST` | `/runner/errands/{id}/reject` | Reject errand |
| `POST` | `/runner/errands/{id}/arrived` | Mark arrived at pickup |
| `POST` | `/runner/errands/{id}/pickup-otp` | Verify pickup OTP |
| `POST` | `/runner/errands/{id}/start` | Start errand execution |
| `POST` | `/runner/errands/{id}/complete` | Submit proof + mark complete |
| `POST` | `/runner/errands/{id}/cancel` | Cancel errand (trust penalty) |
| `POST` | `/runner/errands/{id}/proof` | Upload additional proof |
| `POST` | `/runner/errands/{id}/panic` | Trigger panic button |
| `PUT` | `/runner/errands/{id}/location` | Post GPS tracking update |

**Pickup OTP body:**
```json
{
  "otp": "123456"
}
```

**Complete errand body (proof submission):**
```json
{
  "type": "photo|receipt|signature|note",
  "file_url": "string (S3 URL for photo/receipt/signature)",
  "notes": "string (optional)"
}
```

### Runner Earnings

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/runner/earnings` | Earnings summary + transactions |
| `POST` | `/runner/earnings/withdraw` | Request withdrawal |
| `GET` | `/runner/earnings/withdrawals` | Withdrawal history |
| `PUT` | `/runner/earnings/bank-account` | Update bank details |

**Withdrawal body:**
```json
{
  "amount": 5000
}
```

**Bank account body:**
```json
{
  "bank_name": "string",
  "bank_account_number": "string",
  "bank_account_name": "string",
  "bank_code": "string"
}
```

---

## Admin Endpoints

> All require role: `admin` or `verification_officer`

### Dashboard

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/dashboard` | Platform KPIs |
| `GET` | `/admin/metrics` | Time-series data |
| `GET` | `/admin/live-map` | Active runners with positions |

### Users

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/users` | All users (paginated, filterable) |
| `GET` | `/admin/users/{id}` | User detail |
| `PUT` | `/admin/users/{id}/suspend` | Suspend user |
| `PUT` | `/admin/users/{id}/restore` | Restore suspended user |
| `PUT` | `/admin/users/{id}/blacklist` | Blacklist user |
| `PUT` | `/admin/users/{id}/verify` | Manual verification |
| `DELETE` | `/admin/users/{id}` | Soft delete user |

### Runners

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/runners` | All runners |
| `GET` | `/admin/runners/{id}` | Runner detail |
| `PUT` | `/admin/runners/{id}/approve` | Approve runner |
| `PUT` | `/admin/runners/{id}/suspend` | Suspend runner |
| `PUT` | `/admin/runners/{id}/trust-score` | Adjust trust score |

### KYC

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/kyc` | All KYC submissions |
| `GET` | `/admin/kyc/pending` | Pending submissions |
| `GET` | `/admin/kyc/{id}` | KYC document detail |
| `PUT` | `/admin/kyc/{id}/approve` | Approve KYC |
| `PUT` | `/admin/kyc/{id}/reject` | Reject KYC |
| `PUT` | `/admin/kyc/{id}/request-resubmission` | Request resubmission |

### Errands (Admin)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/errands` | All errands |
| `GET` | `/admin/errands/{id}` | Full errand detail |
| `POST` | `/admin/errands/{id}/reassign` | Reassign to different runner |
| `POST` | `/admin/errands/{id}/cancel` | Admin cancel |
| `GET` | `/admin/errands/{id}/timeline` | Full status history |
| `GET` | `/admin/errands/{id}/tracking` | All tracking logs |

### Finance

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/finance/overview` | Total balances, commissions |
| `GET` | `/admin/finance/escrow` | All escrow records |
| `GET` | `/admin/finance/transactions` | All wallet transactions |
| `POST` | `/admin/finance/refund` | Force refund |
| `POST` | `/admin/finance/release` | Force release escrow |
| `PUT` | `/admin/finance/wallets/{userId}/freeze` | Freeze wallet |
| `PUT` | `/admin/finance/wallets/{userId}/unfreeze` | Unfreeze wallet |

### Disputes (Admin)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/disputes` | All disputes |
| `GET` | `/admin/disputes/{id}` | Dispute detail |
| `PUT` | `/admin/disputes/{id}/assign` | Assign to staff |
| `POST` | `/admin/disputes/{id}/resolve` | Resolve with decision |
| `POST` | `/admin/disputes/{id}/close` | Close dispute |

**Resolve dispute body:**
```json
{
  "resolution_type": "refund|release|partial_refund|no_action",
  "resolution": "string (explanation)",
  "refund_amount": 2000,
  "apply_penalty": true
}
```

### Reports

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/reports/revenue` | Revenue by period |
| `GET` | `/admin/reports/errands` | Errand stats |
| `GET` | `/admin/reports/users` | User growth |
| `GET` | `/admin/reports/incidents` | Panic & disputes |
| `GET` | `/admin/reports/fraud` | Flagged accounts |
| `POST` | `/admin/reports/export` | Export CSV/PDF |

### Settings

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/admin/settings` | All platform settings |
| `PUT` | `/admin/settings` | Update settings |
| `GET` | `/admin/settings/service-areas` | List service areas |
| `POST` | `/admin/settings/service-areas` | Add service area |
| `PUT` | `/admin/settings/service-areas/{id}` | Update service area |
| `DELETE` | `/admin/settings/service-areas/{id}` | Delete service area |

### Notifications (Admin)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/admin/notifications/broadcast` | Broadcast to all users |

---

## Webhooks (No Auth)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/webhooks/stripe` | Stripe payment webhook |
| `POST` | `/webhooks/paystack` | Paystack payment webhook |

---

## Standard Response Format

**Success:**
```json
{
  "success": true,
  "message": "string",
  "data": { ... }
}
```

**Paginated:**
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 72
  }
}
```

**Error:**
```json
{
  "success": false,
  "message": "string",
  "errors": {
    "field": ["validation message"]
  }
}
```

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| `200` | Success |
| `201` | Created |
| `400` | Bad request / validation error |
| `401` | Unauthenticated |
| `403` | Forbidden (wrong role, not verified) |
| `404` | Not found |
| `409` | Conflict (e.g. errand already accepted) |
| `422` | Unprocessable entity (validation) |
| `500` | Internal server error |
