# Implementation Roadmap

Phased plan to implement all Gemini features and the Errandly AI Agent. Each phase has exit criteria before the next begins.

---

## Phase 0 — Foundation (2–3 weeks)

**Goal:** Infrastructure for any Gemini feature + safe tool execution.

| Task | Deliverable |
|------|-------------|
| GCP / API key setup | Vertex or AI Studio project, secrets in `.env` |
| `GeminiClient` wrapper | Structured JSON, vision, function calling |
| DB migrations | `ai_sessions`, `ai_messages`, `ai_requests`, `ai_tool_calls`, `ai_proposals` |
| `AiToolRegistry` + `AiToolExecutor` | Tier enforcement, audit |
| `POST /api/ai/agent` | Basic chat, R0 read tools only |
| `POST /api/ai/confirm` | Proposal execution |
| Feature flags | `AI_AGENT_ENABLED`, per-feature toggles |
| PHPUnit | Tool authz tests |

**Exit criteria:**
- Customer can ask “status of my latest errand?” and get accurate answer via tools  
- Confirmation flow works for a mock proposal  
- All requests audited  

**Doc:** [07-backend-integration.md](./07-backend-integration.md)

**Optional 0b (same sprint):** Keyword `search_policy` (Postgres FTS) — see [09-vector-search-rag.md](./09-vector-search-rag.md)

---

## Phase 1 — P0 features (4–6 weeks)

| Week | Work |
|------|------|
| 1–2 | F01/F02 Smart errand creation (standalone endpoints + agent tools) |
| 2–3 | F04 Proof verification background job + admin flags |
| 3–4 | F05 KYC assist officer UI |
| 4–5 | F03 Agent UX in web (customer) + mobile stub |
| 5–6 | Hardening, rate limits, docs for support team |
| 5–6 | **pgvector** policy ingest + hybrid `search_policy` ([09-vector-search-rag.md](./09-vector-search-rag.md)) |

**Exit criteria:**
- Median errand create time reduced (measure)  
- Proof flags visible on admin errand detail  
- KYC queue shows AI risk badge; officer still approves  

**Feature docs:** [features/01](./features/01-smart-errand-creation.md), [02](./features/02-proof-verification.md), [03](./features/03-kyc-assist.md), [05](./features/05-support-agent.md)

---

## Phase 2 — P1 trust & ops (4–5 weeks)

| Feature | ID |
|---------|-----|
| Dispute copilot | F06 |
| Budget & ETA + address normalizer | F07, F08 |
| Chat moderation | F09 |
| Receipt OCR + GPS consistency | F10, F11 |
| Trust explainer + panic triage | F12, F13 |

**Exit criteria:**
- Admin dispute resolution time ↓  
- <1% false positive rate on chat auto-flag (sample review)  

---

## Phase 3 — P2 scale (6+ weeks)

| Feature | ID |
|---------|-----|
| Matching ranker | F14 |
| Fraud radar | F15 |
| Templates, coach, analytics | F17–F21 |

---

## Phase 4 — P3 product expansion

F22–F25 when corporate/recurring products ship.

---

## Dependency graph

```text
Phase 0 (foundation)
    ├── Phase 1: Smart create, Proof, KYC, Agent UX
    ├── Phase 2: Dispute, Budget/Address, Moderation
    └── Phase 3: Matching, Fraud, Analytics
```

---

## Team split (suggested)

| Squad | Owns |
|-------|------|
| **Platform AI** | GeminiClient, agent loop, tools, safety |
| **Customer UX** | Create flow, agent UI, proposals |
| **Trust & Safety** | Proof, KYC, moderation, disputes |
| **Ops** | Admin dashboards, analytics copilot |

---

## Success metrics

| Metric | Target (6 mo post P1) |
|--------|------------------------|
| Errand create completion rate | +15% |
| Avg chars typed on create | −40% |
| Dispute mean time to resolve | −25% |
| KYC median approval time | −30% |
| Agent CSAT | ≥ 4.0/5 |
| Safety incidents from AI actions | 0 critical |

---

## Environment rollout

1. `local` — mock Gemini optional  
2. `staging` — full Gemini, test cards  
3. `production` — feature flags 5% → 50% → 100%  

---

## Open decisions (track here)

| # | Question | Owner | Status |
|---|----------|-------|--------|
| D1 | Vertex AI vs AI Studio | Eng | TBD |
| D2 | Streaming SSE for agent | Eng | TBD |
| D3 | Pidgin in support agent | Product | TBD |
| D4 | Store chat for model fine-tuning | Legal | No |

Update this table as decisions close.
