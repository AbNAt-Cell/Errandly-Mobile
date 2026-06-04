# Errandly × Gemini — AI Documentation Index

This folder is the **single source of truth** for implementing Gemini-powered features and the **Errandly AI Agent** — an assistant that understands the platform, calls approved tools (Laravel-wrapped APIs), and completes user requests **safely** with human-in-the-loop gates where required.

---

## Who should read what

| Audience | Start here |
|----------|------------|
| Product / founders | [02-feature-catalog.md](./02-feature-catalog.md), [06-implementation-roadmap.md](./06-implementation-roadmap.md) |
| Backend engineers | [03-agent-architecture.md](./03-agent-architecture.md), [04-tool-definitions.md](./04-tool-definitions.md), [07-backend-integration.md](./07-backend-integration.md) |
| ML / AI engineers | [01-system-context-for-gemini.md](./01-system-context-for-gemini.md), [08-gemini-configuration.md](./08-gemini-configuration.md) |
| Security / compliance | [05-safety-governance.md](./05-safety-governance.md) |
| Feature squads | [features/](./features/) — one doc per capability |

---

## Document map

| # | File | Purpose |
|---|------|---------|
| 01 | [system-context-for-gemini.md](./01-system-context-for-gemini.md) | Grounding: architecture, entities, lifecycle, rules Gemini must obey |
| 02 | [feature-catalog.md](./02-feature-catalog.md) | Full AI feature list, modalities, priorities, gates |
| 03 | [agent-architecture.md](./03-agent-architecture.md) | Agent loop, function calling, tool executor, sessions |
| 04 | [tool-definitions.md](./04-tool-definitions.md) | Canonical tool schemas mapped to REST API |
| 05 | [safety-governance.md](./05-safety-governance.md) | What AI may never do; audit; NDPA; escalation |
| 06 | [implementation-roadmap.md](./06-implementation-roadmap.md) | Phased delivery, milestones, dependencies |
| 07 | [backend-integration.md](./07-backend-integration.md) | Laravel modules, DB tables, routes, jobs |
| 08 | [gemini-configuration.md](./08-gemini-configuration.md) | Models, API keys, prompts, structured output |
| 09 | [vector-search-rag.md](./09-vector-search-rag.md) | pgvector, embeddings, RAG corpora, `search_policy` |

### Per-feature implementation plans

| Feature | File |
|---------|------|
| Smart errand creation (text + vision) | [features/01-smart-errand-creation.md](./features/01-smart-errand-creation.md) |
| Proof verification (vision + text) | [features/02-proof-verification.md](./features/02-proof-verification.md) |
| KYC assist (vision + text) | [features/03-kyc-assist.md](./features/03-kyc-assist.md) |
| Dispute copilot | [features/04-dispute-copilot.md](./features/04-dispute-copilot.md) |
| Support agent (RAG + tools) | [features/05-support-agent.md](./features/05-support-agent.md) |
| Matching, fraud, chat moderation | [features/06-matching-fraud-moderation.md](./features/06-matching-fraud-moderation.md) |
| Budget, address, ops analytics | [features/07-budget-address-ops.md](./features/07-budget-address-ops.md) |

---

## Core design principle

> **Gemini never calls the Errandly API directly.**  
> All actions flow: **Client → `POST /api/ai/agent`** → **Laravel `AiAgentService`** → **`AiToolExecutor`** (authz + policy) → **existing Services/Controllers** → **Postgres**.

This preserves escrow rules, OTP flows, KYC officer authority, and `public_id`-based resource access.

---

## Related platform docs

- [../README.md](../README.md) — product overview  
- [../API_REFERENCE.md](../API_REFERENCE.md) — REST endpoints  
- [../DATABASE_SCHEMA.md](../DATABASE_SCHEMA.md) — tables  
- [../BACKEND.md](../BACKEND.md) — Laravel structure  

---

## Quick glossary

| Term | Meaning |
|------|---------|
| **Tool** | A named function Gemini can invoke (e.g. `get_errand_status`) |
| **Agent turn** | One user message → zero or more tool calls → final reply |
| **Proposal** | AI-filled data shown for user confirm (no side effects) |
| **Confirmed action** | User tapped “Confirm”; server executes write tool once |
| **Grounding pack** | Static + dynamic context injected each turn (role, policies, errand summary) |
