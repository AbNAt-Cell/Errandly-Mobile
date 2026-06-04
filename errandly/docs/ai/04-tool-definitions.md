# AI Tool Definitions (Function Calling)

Canonical tools for the Errandly AI Agent. Implement handlers in `AiToolRegistry` that delegate to existing Services.

**Naming:** `snake_case` for Gemini function names.  
**IDs:** Always `public_id` (UUID) for errands in arguments.

---

## Tool declaration format (Gemini)

Each tool is registered as:

```json
{
  "name": "get_my_errands",
  "description": "List the authenticated user's errands, optionally filtered by status.",
  "parameters": {
    "type": "object",
    "properties": {
      "status": { "type": "string", "description": "Optional status filter" },
      "limit": { "type": "integer", "maximum": 20, "default": 10 }
    }
  }
}
```

---

## R0 — Read tools

### `get_me`
- **Roles:** all  
- **API:** `GET /api/auth/me`  
- **Returns:** profile, roles, kyc_status  

### `get_wallet`
- **Roles:** customer, runner  
- **API:** `GET /api/wallet`  

### `get_my_errands`
- **Roles:** customer → `GET /api/customer/errands`; runner → `GET /api/runner/errands/my-errands`  
- **Args:** `status?`, `limit?`  

### `get_errand`
- **Roles:** customer, runner (assigned), admin  
- **API:** role-appropriate `GET .../errands/{public_id}`  
- **Args:** `public_id` (required)  

### `track_errand`
- **Roles:** customer  
- **API:** `GET /api/customer/errands/{public_id}/tracking`  

### `get_messages`
- **Roles:** participant  
- **API:** `GET /api/messages/conversations/{public_id}`  

### `get_notifications`
- **Roles:** all  
- **API:** `GET /api/notifications`  

### `get_kyc_status`
- **Roles:** all  
- **API:** `GET /api/kyc`  

### `get_trust_score` (runner)
- **Roles:** runner  
- **API:** `GET /api/runner/trust-score`  

### `explain_trust_score` (runner)
- **Roles:** runner  
- **Handler:** Read `TrustScoreService` breakdown + format via template (optional small Gemini pass)  
- **Tier:** R0 (read-only narrative)  

### `search_policy`
- **Roles:** all  
- **Handler:** RAG over static policy chunks (escrow, OTP, cancel rules) — no DB write  

---

## R1 — Analyze tools (no side effects)

### `parse_errand_from_text`
- **Roles:** customer  
- **Handler:** Gemini structured output → errand draft JSON  
- **Returns:** proposal fields, confidence, clarifying_questions[]  

### `parse_errand_from_image`
- **Roles:** customer  
- **Args:** `image_url` or `media_id` (S3 pre-signed)  
- **Handler:** Gemini Vision → same draft shape as above  

### `suggest_budget_and_eta`
- **Roles:** customer  
- **Args:** `category`, `pickup_lat`, `pickup_lng`, `dest_lat`, `dest_lng`, `urgency?`  
- **Handler:** rules + historical aggregates; optional Gemini explanation  

### `normalize_address`
- **Roles:** customer, runner  
- **Args:** `free_text`, `city?`  
- **Returns:** candidate addresses + coords for map confirm  

### `analyze_proof_submission` (internal/background)
- **Roles:** system job; admin read  
- **Args:** `public_id`, `proof_id`  
- **Returns:** match_score, flags[], summary  

### `analyze_kyc_submission` (internal)
- **Roles:** system; officer UI  
- **Args:** `kyc_document_id`  
- **Returns:** extracted fields, face_match_score, flags[]  

### `summarize_dispute` (admin)
- **Roles:** admin, verification_officer (dispute only)  
- **Args:** `dispute_id`  

### `moderate_message_text`
- **Roles:** system background  
- **Args:** `message_id`  

---

## R2 — Propose tools (writes to `ai_proposals` only)

### `propose_create_errand`
- **Roles:** customer  
- **Args:** full errand payload per API validation  
- **Returns:** `proposal_id`, `estimated_total_kobo`, warnings[]  

### `propose_cancel_errand`
- **Roles:** customer, runner (policy-checked)  
- **Args:** `public_id`, `reason`  
- **Returns:** `proposal_id`, refund_preview  

### `propose_send_message`
- **Roles:** customer, runner (participant)  
- **Args:** `public_id`, `content`  

### `propose_open_dispute`
- **Roles:** customer, runner  
- **Args:** `public_id`, `type`, `description`  

---

## R3 — Confirmed execution (requires `POST /api/ai/confirm`)

| Proposal type | Executes |
|---------------|----------|
| `create_errand` | `POST /api/customer/errands` via `ErrandService` |
| `cancel_errand` | cancel endpoints |
| `send_message` | `POST /api/messages/conversations/{public_id}` |
| `open_dispute` | `POST /api/disputes` |

**Not available as agent tools (R4 — forbidden):**
- `confirm_completion` (OTP must be typed by user in UI)
- `accept_errand` (runner explicit tap)
- `approve_kyc` / `reject_kyc`
- `admin_refund` / `release_escrow`
- `adjust_trust_score`
- `trigger_panic` (dedicated UI only — optional read-only `explain_panic` instead)

---

## Runner-specific tools

### `list_available_errands`
- **Roles:** runner (verified, online)  
- **API:** `GET /api/runner/errands/available`  

### `get_runner_earnings`
- **Roles:** runner  
- **API:** `GET /api/runner/earnings`  

---

## Admin-only tools

### `admin_list_disputes`
- **API:** `GET /api/admin/disputes`  

### `admin_get_errand`
- **API:** `GET /api/admin/errands/{public_id}`  

### `admin_analytics_query` (P2)
- **Read-only** SQL via restricted connection or pre-approved report endpoints  

---

## Tool result shape (to Gemini)

```json
{
  "ok": true,
  "data": { },
  "user_message_hint": "Optional short context for model"
}
```

On failure:

```json
{
  "ok": false,
  "error_code": "ERRAND_NOT_FOUND",
  "message": "No errand with that id for this user."
}
```

---

## Role → tool matrix (summary)

| Tool | customer | runner | admin |
|------|:--------:|:------:|:-----:|
| get_my_errands | ✓ | ✓* | ✓ |
| parse_errand_* | ✓ | | |
| propose_create_errand | ✓ | | |
| list_available_errands | | ✓ | |
| summarize_dispute | | | ✓ |
| analyze_kyc_* | | | ✓† |

\* runner uses my-errands variant  
† officer + admin  

Full matrix maintained in `config/ai_tools.php` when implemented.

---

## Implementation checklist per tool

- [ ] JSON schema in registry  
- [ ] Handler class method  
- [ ] Policy test (PHPUnit)  
- [ ] Audit log on execute  
- [ ] Document in this file  

See [07-backend-integration.md](./07-backend-integration.md).
