# Errandly — Feature Readiness Checklist

Tracked implementation status for functional features. Update this file when wiring or validation changes.

## Status definitions

| Status | Criteria |
|--------|----------|
| **Implemented** | Backend routes + services exist; Web and/or Mobile expose the workflow (screens + API calls) |
| **Partially validated** | Implemented + some automated or manual proof, but not full cross-client E2E |
| **Fully validated** | Implemented + feature/E2E tests + integrations verified in staging |

## Audit columns

- **B** Backend API
- **W** Web (`errandly/web`)
- **M** Mobile (`errandly/mobile`)
- **T** Automated tests
- **I** External integrations (SMS, payments, Pusher, FCM)

---

## Feature matrix

| # | Feature | Status | B | W | M | T | I | Notes |
|---|---------|--------|---|---|---|---|---|-------|
| 1 | Auth & account lifecycle | Implemented | ✓ | ✓ | ✓ | △ | △ | Login, register, forgot/reset, verify-phone screens |
| 2 | Runner KYC & verification | Implemented | ✓ | ✓ | ✓ | △ | △ | `/runner/kyc`, mobile `RunnerKycScreen` |
| 3 | Customer errand creation | Implemented | ✓ | ✓ | ✓ | △ | △ | Wizard + AI assistant |
| 4 | Runner fulfillment lifecycle | Implemented | ✓ | ✓ | ✓ | △ | △ | OTP, proof, complete alias |
| 5 | Customer cancellation & refunds | Implemented | ✓ | ✓ | ✓ | △ | △ | Cancel on errand detail |
| 6 | Runner cancellation & reassignment | Implemented | ✓ | ✓ | ✓ | △ | △ | `AutoReassignErrand` → notify nearby |
| 7 | Wallet, escrow, funding | Implemented | ✓ | ✓ | ✓ | △ | △ | Paystack init + verify fallback |
| 8 | Runner withdrawals & bank | Implemented | ✓ | ✓ | ✓ | △ | △ | Paths: `earnings/withdraw`, `earnings/bank-account` |
| 9 | Disputes & resolution | Implemented | ✓ | ✓ | ✓ | △ | △ | Raise dispute on errand detail; admin UI |
| 10 | Messaging | Implemented | ✓ | ✓ | ✓ | △ | △ | Conversation threads + polling |
| 11 | Live tracking | Implemented | ✓ | ✓ | ✓ | △ | △ | Map + tracking poll on customer detail |
| 12 | Panic & safety | Implemented | ✓ | ✓ | ✓ | △ | △ | Panic on customer/runner errand detail |
| 13 | Ratings & trust score | Implemented | ✓ | ✓ | ✓ | △ | △ | Post-completion rating modal |
| 14 | Notifications | Implemented | ✓ | ✓ | ✓ | △ | △ | List/read; FCM via device token |
| 15 | Admin operations | Implemented | ✓ | ✓ | — | △ | △ | Web-only admin suite |
| 16 | AI assistant & analysis | Implemented | ✓ | ✓ | ✓ | ✓ | △ | Web assistant + mobile support screen |

**Implemented (audit target):** 16 / 16  
**Fully validated:** run `php artisan test` + manual staging checklist in [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## Per-feature flows (quick reference)

### 1. Auth
`Register → Login → Verify phone (optional) → Profile / password / device token → Logout`  
Forgot: `/auth/forgot-password` → email reset.

### 2. KYC
`Submit docs → under_review → approve/reject/resubmit` → runner `runner.verified` middleware.

### 3–4. Errand lifecycle
`posted → pending_assignment → accepted → runner_en_route → item_picked → in_progress → awaiting_confirmation → completed`  
OTPs: pickup (runner), delivery (customer).

### 5–6. Cancellation
Customer tiered refunds; runner cancel → trust penalty → `NotifyNearbyRunners`.

### 7–8. Money
Fund wallet → escrow on create → release on OTP confirm; runner withdraw + bank account.

### 9. Disputes
`POST /disputes` → evidence → admin resolve → escrow action.

### 10–12. Comms & safety
Messages per errand; tracking logs; panic freezes escrow.

### 13. Ratings
`POST /ratings` after `completed` → trust score update.

### 14–16. Ops & AI
In-app notifications; admin dashboards; `/api/ai/*` agent and analysis.

---

## Upgrade path to Fully validated

1. Add `tests/Feature/ErrandLifecycleTest.php` coverage for happy path.
2. Configure Paystack, Termii, Pusher, FCM in staging; run manual E2E script.
3. Add Playwright smoke tests for web critical paths.
4. Add Flutter integration tests for login → create errand → accept (optional).

---

*Last updated: 2026-06-03 — closed partial gaps: mobile customer cancel/KYC/notifications, runner forgot-password + bank UI, web tracking map + runner bank form, FCM device token on login/register.*
