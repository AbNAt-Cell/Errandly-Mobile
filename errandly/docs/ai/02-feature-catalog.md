# AI Feature Catalog

All Gemini-powered capabilities for Errandly, with modality, priority, human gates, and agent integration mode.

**Integration modes:**
- **Standalone** — dedicated endpoint (e.g. `POST /api/ai/errands/parse-image`)
- **Agent tool** — exposed as function callable by the Errandly AI Agent
- **Background job** — async analysis (proof scan, fraud signals)

---

## Priority legend

| Priority | Meaning |
|----------|---------|
| **P0** | MVP AI — ship first |
| **P1** | High value, phase 2 |
| **P2** | Growth / ops scale |
| **P3** | Phase 2 product (corporate, recurring) |

---

## P0 — Foundation + core UX

| ID | Feature | Modality | Mode | Human gate |
|----|---------|----------|------|------------|
| F01 | **Smart errand creation (vision)** | Vision + text | Standalone + Agent | User confirms form before `create_errand` |
| F02 | **Smart errand creation (NL text)** | Text | Agent | User confirms form |
| F03 | **Errandly AI Agent (support + actions)** | Text + tools | Agent | Per-tool policy (see [04-tool-definitions.md](./04-tool-definitions.md)) |
| F04 | **Proof verification (vision)** | Vision + text | Background + Admin UI | Flags only; no auto-complete |
| F05 | **KYC assist (vision)** | Vision + text | Admin queue | Officer approves/rejects |

---

## P1 — Trust, ops, marketplace health

| ID | Feature | Modality | Mode | Human gate |
|----|---------|----------|------|------------|
| F06 | **Dispute copilot** | Vision + text | Admin | Admin resolves dispute |
| F07 | **Budget & ETA suggester** | Text + data | Standalone + Agent | Suggestion only |
| F08 | **Address / landmark normalizer** | Text + vision | Agent | User confirms map |
| F09 | **Chat moderation** | Text (+ STT) | Background | Auto-flag; admin suspend |
| F10 | **Receipt OCR & reconciliation** | Vision | Background | Customer notified; dispute path |
| F11 | **GPS vs proof consistency** | Vision + geo | Background | Trust review flag |
| F12 | **Trust score explainer** | Text | Agent (read) | Read-only |
| F13 | **Panic triage summary** | Text | Background + Admin | Human emergency protocol |

---

## P2 — Scale & retention

| ID | Feature | Modality | Mode | Human gate |
|----|---------|----------|------|------------|
| F14 | **Runner matching ranker** | Tabular + text | Job | Runner accepts manually |
| F15 | **Fraud & collusion radar** | Tabular | Background | Admin / risk queue |
| F16 | **Cancellation / dispute classifier** | Text | Background | Rules engine applies refund |
| F17 | **Errand templates (“post again”)** | Text | Agent | User confirms post |
| F18 | **Runner earnings coach** | Text | Agent (read) | Read-only insights |
| F19 | **Rating summarization** | Text | Read | Display only |
| F20 | **Admin analytics NL query** | Text + SQL tool | Admin Agent | Read-only DB role |
| F21 | **Localized notification copy** | Text | Job | Template approval optional |

---

## P3 — Future product

| ID | Feature | Modality | Mode | Human gate |
|----|---------|----------|------|------------|
| F22 | **Corporate bulk intake** | Vision + text | Admin | Admin publishes errands |
| F23 | **Recurring errand NL parser** | Text | Agent | User confirms schedule |
| F24 | **Insurance / high-value risk** | Text + vision | Standalone | Opt-in product rules |
| F25 | **Category-specific proof (queue, documents)** | Vision | Background | Same as F04 |

---

## Feature → Gemini model mapping (default)

| Use case | Recommended model | Why |
|----------|-------------------|-----|
| Agent chat + tools | `gemini-2.0-flash` | Low latency, function calling |
| Vision (errand photo, proof, receipt) | `gemini-2.0-flash` or `gemini-2.5-pro` | Quality vs cost tradeoff |
| KYC document OCR | `gemini-2.5-pro` | Higher accuracy on IDs |
| Dispute copilot (long context) | `gemini-2.5-pro` | Multi-doc reasoning |
| Background batch | `gemini-2.0-flash` | Cost |

Configurable per environment: [08-gemini-configuration.md](./08-gemini-configuration.md)

---

## Cross-cutting requirements (all features)

1. **Audit log** every request/response (redact PII in stored prompts where possible).
2. **Rate limits** per user role (see [05-safety-governance.md](./05-safety-governance.md)).
3. **No direct API access** from Gemini — tools only.
4. **public_id** for all errand references in agent context.
5. **Fail closed** on tool errors — agent explains failure, does not guess state.

---

## Links to detailed plans

| Feature area | Doc |
|--------------|-----|
| F01, F02, F07, F08, F17 | [features/01-smart-errand-creation.md](./features/01-smart-errand-creation.md) |
| F04, F10, F11, F25 | [features/02-proof-verification.md](./features/02-proof-verification.md) |
| F05 | [features/03-kyc-assist.md](./features/03-kyc-assist.md) |
| F06, F16 | [features/04-dispute-copilot.md](./features/04-dispute-copilot.md) |
| F03, F12, F18 | [features/05-support-agent.md](./features/05-support-agent.md) |
| F09, F14, F15 | [features/06-matching-fraud-moderation.md](./features/06-matching-fraud-moderation.md) |
| F07, F08, F20, F21 | [features/07-budget-address-ops.md](./features/07-budget-address-ops.md) |
