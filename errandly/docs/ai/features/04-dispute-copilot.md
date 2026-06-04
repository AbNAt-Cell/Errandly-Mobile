# F06 / F16 — Dispute Copilot & Classification

**Users:** Admins, verification officers (disputes)  
**Modality:** Text + vision (evidence photos)

---

## 1. Dispute copilot (F06)

### Trigger
Admin opens dispute `GET /admin/disputes/{id}` → button **Generate AI summary**  
Or auto-queue on `Dispute::STATUS_OPEN`.

### Inputs assembled
- Errand snapshot (title, description, budget, status timeline)
- `messages` (full thread)
- `proof_submissions` + prior AI proof analysis
- `tracking_logs` summary (distance, duration)
- `dispute_evidence` files
- Cancellation history if any

### Output
```json
{
  "timeline_summary": "bullet strings",
  "customer_claim": "string",
  "runner_claim": "string",
  "key_evidence": [{ "source": "proof|chat|gps", "citation": "..." }],
  "suggested_resolution": "refund|partial_refund|release|no_action",
  "suggested_partial_percent": 50,
  "confidence": 0.7,
  "questions_for_admin": ["string"]
}
```

### Admin action
Officer chooses resolution in existing UI → `AdminDisputeController::resolve` — **unchanged**.

---

## 2. Classification (F16)

On `POST /api/disputes` (user raises dispute):
- Gemini classifies `type` consistency (user-selected vs description)
- Suggests priority (harassment → urgent)
- Tags for routing

Store in `disputes.metadata.ai_classification`.

---

## 3. Agent tools (admin)

- `summarize_dispute` — `{ dispute_id }`  
- `admin_get_errand` — linked errand context  
- **No** `resolve_dispute` tool  

---

## 4. Prompt guardrails

```text
You assist human dispute resolution. You do not have authority to move money.
Cite specific evidence. If insufficient evidence, say so.
Suggested resolution is advisory.
```

---

## 5. Escrow awareness

Copilot must understand:
- Frozen escrow state
- Refund vs release implications
- OTP completion status

Inject `escrow.status` and `errand.payment_status` in context.

---

## 6. Tasks

- [ ] `DisputeSummarizer` service  
- [ ] `AiDisputeController`  
- [ ] Admin UI panel + copy buttons  
- [ ] Classification on store (async)  
- [ ] Audit log for summaries shown to officers  

---

## 7. Metrics

- Mean time to resolve dispute  
- % officers accepting suggested resolution type  
- Appeal/overturn rate  
