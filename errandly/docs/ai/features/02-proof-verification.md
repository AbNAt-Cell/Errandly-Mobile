# F04 / F10 / F11 / F25 — Proof Verification

**Modality:** Gemini Vision + errand text context  
**Mode:** Background job + admin/customer visibility

---

## 1. Purpose

When runners upload proof (`proof_submissions`), analyze images to:
- Match items/scene to `item_details` and `description`
- Validate receipts (OCR total, merchant, date)
- Detect reuse / irrelevant images
- Compare timing vs `tracking_logs` (GPS consistency)

**Never** auto-complete errand or release escrow.

---

## 2. Trigger

```php
// After ErrandService::submitProof
ProofSubmissionCreated::dispatch($proof);
→ AnalyzeProofSubmissionJob::dispatch($proof->id);
```

---

## 3. Analysis pipeline

```text
1. Load errand + customer description + category
2. Load proof image(s) from S3 (pre-signed)
3. Load last N tracking_logs points
4. Gemini Vision prompt → structured result
5. Save ai_vision_analyses + flags on proof_submissions.meta
6. If severity >= threshold → notify customer + admin queue
```

---

## 4. Output schema

```json
{
  "relevance_score": 0.0,
  "matches_errand_description": true,
  "receipt_detected": true,
  "receipt_total_ngn": 3500,
  "receipt_matches_budget": true,
  "flags": [
    { "code": "AMOUNT_EXCEEDS_BUDGET", "severity": "medium", "detail": "..." }
  ],
  "summary": "Receipt from Shoprite shows ₦3,500; errand budget ₦3,000.",
  "gps_consistency": {
    "consistent": true,
    "note": "Last GPS ping 200m from destination"
  }
}
```

---

## 5. Flag codes

| Code | Action |
|------|--------|
| `LOW_RELEVANCE` | Soft flag; customer can still confirm with OTP |
| `RECEIPT_MISMATCH` | Prompt customer to review before OTP |
| `POSSIBLE_REUSE` | Admin review; trust penalty candidate |
| `GPS_INCONSISTENT` | Admin review |
| `BLURRY_UNREADABLE` | Ask runner to re-upload via app |

---

## 6. Gemini prompt (outline)

```text
You verify proof-of-errand for a marketplace. Errand category: {category}.
Customer asked: {description}. Item details: {item_details}.
Runner notes: {notes}.

Analyze the image(s). Return JSON only.
Do not approve payment — only assess evidence quality.
```

Include receipt OCR fields for `grocery_purchase`, `shopping_assistance`, `prescription_pickup`.

---

## 7. UI surfaces

| Surface | Display |
|---------|---------|
| Customer errand detail | Banner: “Receipt higher than budget — review before confirming” |
| Admin errand detail | Proof card with AI score + flags |
| Runner | Optional: “Photo unclear, please retake” (automated push) |

---

## 8. Agent tool (read-only)

`analyze_proof_submission` — admin only; on-demand refresh.

Customers use support agent: “Was my proof accepted?” → agent reads stored analysis via `get_errand` + metadata.

---

## 9. Receipt OCR (F10)

Dedicated sub-prompt for receipt images:
- Line items (best effort)
- Total, tax, merchant name, date
- Compare `receipt_total_ngn` to `errand.budget` (kobo conversion)

If over budget → suggest customer top-up or dispute path (explain via agent, no auto charge).

---

## 10. Category-specific (F25)

| Category | Extra checks |
|----------|--------------|
| `queue_standing` | Ticket/queue photo, timestamp plausibility |
| `document_*` | Envelope/seal visible, office context |
| `package_pickup` | Label partial match if visible |

---

## 11. Tasks

- [ ] `ProofAnalyzer` service  
- [ ] Migration: `proof_submissions.ai_analysis` JSON column  
- [ ] Job + retry policy  
- [ ] Admin UI component  
- [ ] Customer warning component  
- [ ] PHPUnit with fixture receipt images  

---

## 12. Safety

- Runner not penalized automatically on low score alone  
- `fake_proof` trust penalty remains **admin/officer** decision  
- Store image hash to detect duplicate uploads across errands  
