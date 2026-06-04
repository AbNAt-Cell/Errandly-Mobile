# F09 / F14 / F15 — Matching, Fraud & Chat Moderation

**Priority:** P1–P2  
**Mode:** Mostly background jobs; some agent read tools

---

## 1. Chat moderation (F09)

### Trigger
`MessageCreated` → `ScanMessageModerationJob`

### Analyze
- Off-platform payment requests
- Harassment, threats
- Personal contact solicitation
- Scam patterns

### Output
```json
{
  "severity": "none|low|medium|high",
  "categories": ["off_platform_payment"],
  "action": "none|flag|urgent_flag",
  "summary": "..."
}
```

### Actions
| Severity | System response |
|----------|-----------------|
| low | Log only |
| medium | Flag in admin; notify user generic warning |
| high | Freeze chat optional; admin alert; link to dispute template |

**No auto-suspend** without admin.

### Voice messages
Transcribe with Google STT or Gemini audio → then text moderation.

---

## 2. Runner matching ranker (F14)

### Current
`NotifyNearbyRunners` — geo + `pending_assignment`.

### Enhanced scoring

```text
score = w1 * trust_score
      + w2 * category_match(skills)
      + w3 * acceptance_rate
      - w4 * active_errand_load
      - w5 * distance_km
```

Gemini optional: generate human explanation for runner app (“You’re a top match because…”).

### Implementation
- PHP computes ranking in `NotifyNearbyRunners` or new `RunnerMatchingService`
- Gemini not required for v1 — only for explanations

### Agent
- `list_available_errands` returns pre-sorted list

---

## 3. Fraud & collusion radar (F15)

### Signals (batch + event-driven)

| Signal | Detection |
|--------|-------------|
| Same device token, multiple accounts | DB query |
| Customer↔runner always paired | Graph |
| Rapid fund→post→complete→withdraw | Timeline |
| GPS static during `in_progress` | tracking_logs |
| Duplicate proof image hash | vision table |
| Many disputes one dyad | counts |

### Gemini role
Summarize cluster for admin: “Accounts 12 and 45 show 8 shared completion patterns…”

### Output
`fraud_signals` table or `users.risk_metadata` JSON + admin queue.

### Agent
**No** auto-freeze tool. Admin uses existing `freezeWallet`.

---

## 4. Tasks

- [ ] `MessageModerationScanner`  
- [ ] `RunnerMatchingService` refactor  
- [ ] `FraudSignalAggregator` nightly job  
- [ ] Admin “Risk” queue page  
- [ ] Tests for pattern SQL  

---

## 5. Safety

- False positive harassment flags → human review before suspend  
- Document fraud model limitations to admins  
- Avoid discriminatory features (area, name) in scoring weights  
