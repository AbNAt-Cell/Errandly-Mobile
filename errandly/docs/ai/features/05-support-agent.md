# F03 / F12 / F18 — Errandly AI Agent (Support & Insights)

**Priority:** P0 (core agent), P1 (trust explainer, earnings coach)

---

## 1. Product definition

**Errandly AI Agent** is the primary conversational interface for:
- Answering “what’s happening with my errand?”
- Guiding OTP, wallet, KYC steps
- Proposing safe actions (create/cancel/message) with confirmation
- Explaining trust scores and earnings (read-only)

**Channels:** Web customer/runner layouts, mobile FAB, future WhatsApp (out of scope).

---

## 2. Example dialogs

### Customer
| User | Agent behavior |
|------|----------------|
| “Where is my runner?” | `get_errand` + `track_errand` → map link + ETA language |
| “Cancel my delivery” | `propose_cancel_errand` → confirm card |
| “How do I pay?” | `search_policy` + wallet link |
| “Post this list” [image] | `parse_errand_from_image` → `propose_create_errand` |

### Runner
| User | Agent behavior |
|------|----------------|
| “Why is my score 62?” | `explain_trust_score` |
| “Any jobs near me?” | `list_available_errands` (if online) |
| “What do I do at pickup?” | Policy + errand status |

### Admin
| User | Agent behavior |
|------|----------------|
| “Summarize dispute 42” | `summarize_dispute` |
| “Open disputes today” | `admin_list_disputes` |

---

## 3. RAG knowledge base

Static chunks (markdown → embeddings):
- Escrow & fees (15%)
- OTP steps
- Cancellation refund rules
- KYC requirements
- Panic button
- Service areas (Uyo)

Tool: `search_policy(query)` returns top-k chunks.

**Retrieval phases:** (1) Postgres full-text keyword search in Phase 0b, (2) **pgvector + hybrid search** in Phase 1 — full design in [09-vector-search-rag.md](../09-vector-search-rag.md).

**Do not RAG** live errand state — use tools.

---

## 4. API contract

### `POST /api/ai/agent`

**Request:**
```json
{
  "message": "Where is my runner?",
  "session_id": "uuid-optional",
  "context": {
    "page": "errand_detail",
    "errand_public_id": "550e8400-..."
  }
}
```

**Response:**
```json
{
  "session_id": "uuid",
  "reply": "Your runner Ada is en route...",
  "proposals": [],
  "suggested_actions": [
    { "type": "open_tracking", "public_id": "..." }
  ]
}
```

### `POST /api/ai/confirm`

```json
{
  "proposal_id": "uuid",
  "confirmation_token": "from-proposal-response"
}
```

---

## 5. UI components (web)

| Component | Purpose |
|-----------|---------|
| `AiChatDrawer` | Slide-over chat |
| `ProposalCard` | Create/cancel preview |
| `ConfirmBar` | Confirm/Cancel buttons |
| `ToolStatus` | “Checking your errand…” |

Mobile: equivalent Flutter widgets.

---

## 6. System prompt highlights

- Always prefer tools over memory  
- Nigerian English, clear, concise  
- Never promise refund amount without `propose_cancel` result  
- Panic: instruct to use in-app panic button immediately  

---

## 7. Trust score explainer (F12)

Tool returns structured breakdown from `TrustScoreService`; agent narrates:

```text
Your score is 62/100 mainly because of 2 runner cancellations (-10) 
and a dispute last week (-10). Completing 5 more errands without 
issues could recover ~8 points.
```

No Gemini math on raw data — PHP computes numbers.

---

## 8. Runner earnings coach (F18)

Periodic job or on-demand tool:
- Aggregates `runner_profiles.total_earnings`, errand categories, time of day
- Gemini generates weekly tip (read-only notification)

---

## 9. Implementation checklist

- [ ] Phase 0 agent loop  
- [ ] R0 tools wired  
- [ ] R2/R3 proposals  
- [ ] Web chat drawer  
- [ ] Mobile FAB (phase 1b)  
- [ ] Policy RAG v1  

See [03-agent-architecture.md](../03-agent-architecture.md).

---

## 10. Failure modes

| Issue | Mitigation |
|-------|------------|
| Stale status | Always call `get_errand` when `public_id` in context |
| User asks for OTP | Direct to OTP input UI, don’t tool |
| Jailbreak | Safety filters + tier limits |
