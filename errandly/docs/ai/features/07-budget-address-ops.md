# F07 / F08 / F17 / F20 / F21 — Budget, Address, Templates & Ops

**Priority:** P1–P2

---

## 1. Budget & ETA suggester (F07)

Covered in [01-smart-errand-creation.md](./01-smart-errand-creation.md).

**Endpoint:** `POST /api/ai/errands/suggest-budget`  
**Agent tool:** `suggest_budget_and_eta`

**Data sources:**
- Historical median budget by category + distance bucket
- `service_areas` density
- `urgency` multiplier

---

## 2. Address / landmark normalizer (F08)

### Problem
Users enter: *“Opposite Zenith Bank, Use Offot”* instead of formal addresses.

### Flow
1. `normalize_address(free_text, city=Uyo)`
2. Geocoder + Gemini disambiguation if multiple matches
3. Return 1–3 candidates with lat/lng + confidence
4. Client shows map picker

### Agent
User: “Pickup at DHL near Ibom Plaza” → tool → “I found 2 matches — which one?”

### Validation
Server checks candidate inside `service_areas` before `propose_create_errand`.

---

## 3. Errand templates — “Post again” (F17)

### Logic
- Query last 5 completed errands for customer
- Detect repeat patterns (same addresses, category)
- `propose_create_errand` with prefilled payload

### Agent
“Post my usual pharmacy run” → match template → proposal

### Privacy
Only user’s own history via `get_my_errands`.

---

## 4. Admin analytics NL (F20)

### Scope
Read-only queries against reporting tables or pre-built report endpoints.

### Architecture options

| Option | Description |
|--------|-------------|
| A | Gemini generates SQL → execute on **read replica** with allowlist |
| B | Map intents to existing `AdminReportController` methods |

**Recommend B for v1** (safer).

### Agent tools (admin)
- `admin_report_revenue({ from, to })`
- `admin_report_errands({ from, to })`
- `admin_report_users({ metric })`

Gemini chooses tool — never raw SQL in v1.

---

## 5. Localized notifications (F21)

### Trigger
On `NotificationService::send` optional hook.

### Input
Event type + user locale + key facts (errand title, runner name).

### Output
SMS/push body ≤ 160 chars for SMS.

### Guard
Template approval mode in staging; compare to default English.

---

## 6. Implementation order

1. Budget suggest (rules engine)  
2. Address normalize (geocoder + light Gemini)  
3. Templates (SQL only)  
4. Admin report tools  
5. Notification copy (optional)  

---

## 7. Metrics

- Address correction rate before post  
- Budget suggestion acceptance %  
- Template usage %  
- Admin time saved on reports (survey)  
