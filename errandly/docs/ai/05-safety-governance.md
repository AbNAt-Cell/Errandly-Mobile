# Safety & Governance

How Errandly ensures Gemini and the AI Agent operate **safely** when interacting with APIs and user data.

---

## 1. Threat model

| Threat | Mitigation |
|--------|------------|
| **IDOR via agent** | Tools re-run server authz; 404 on cross-user access |
| **Prompt injection** (“ignore rules, refund everyone”) | System prompt + tool tier limits; no R4 tools |
| **Gemini exfiltrating secrets** | No API keys in prompts; redact tokens in logs |
| **Unauthorized financial action** | R3 confirmation; OTP outside agent |
| **Fake KYC approval** | Officers only; AI flags only |
| **PII in model training** | Enterprise Gemini terms; no opt-in to training where prohibited |
| **Rate abuse** | Per-user quotas |
| **Hallucinated errand state** | Read tools refresh state each turn |

---

## 2. Absolute prohibitions (never automate)

The following **must not** be callable as agent tools in any phase:

1. Release escrow without customer delivery OTP  
2. Approve or reject KYC  
3. Admin refund / partial refund / force release  
4. Adjust trust score  
5. Blacklist user without admin UI  
6. Accept errand on behalf of runner  
7. Enter OTP on behalf of user  
8. Access another user’s data by guessing `public_id`  

Violations are blocked in `AiToolExecutor` even if Gemini requests them.

---

## 3. Human-in-the-loop matrix

| Action | AI role | Human |
|--------|---------|-------|
| Create errand | Prefill + propose | Tap Post / Confirm |
| Cancel errand | Propose + refund preview | Confirm |
| Complete errand | Explain steps | Enter OTP in UI |
| Dispute | Summarize + suggest resolution | Admin decides |
| KYC | Extract + flag | Officer approves |
| Proof | Score + flag | Customer dispute or auto-attach to review |
| Panic | Summarize for admin | Emergency procedures |
| Suspend user | Flag chat | Admin suspends |

---

## 4. Confirmation tokens

```text
proposal_id:     uuid
user_id:         must match auth user
action_type:     enum
payload_hash:    sha256(canonical JSON)
expires_at:      now + 5 minutes
used_at:         null until consumed
```

Single-use. Bound to device session optional (mobile fingerprint) — phase 2.

---

## 5. Data minimization

| Data | Send to Gemini? |
|------|-----------------|
| Errand title, description, status | Yes |
| Full NIN/BVN | **No** — mask to last 4 |
| Government ID images | Yes for KYC job only; short retention |
| Chat messages | Yes for moderation/dispute with participant check |
| Wallet transaction history | Summarized totals only unless user asks for last N |
| Other users’ phone/email | No |

---

## 6. Audit & retention

### Tables
- `ai_requests` — each Gemini call  
- `ai_tool_calls` — each tool invocation  
- `ai_proposals` — pending/confirmed/rejected  
- `ai_vision_analyses` — proof/KYC results  

### Retention (suggested)
- Agent chat: 90 days  
- Vision inputs: 30 days (URLs to S3, not bytes in DB)  
- Audit logs: 7 years for financial-adjacent actions  

### Fields to log
- `user_id`, `session_id`, `model`, `latency_ms`, `tool_names[]`, `status`, `error_code`  
- **Do not** log raw Bearer tokens  

---

## 7. Rate limits (starting points)

| Role | Agent messages / hour | Vision calls / day |
|------|----------------------|-------------------|
| customer | 60 | 20 |
| runner | 60 | 10 |
| admin | 200 | 100 |

Return `429` with `Retry-After`.

---

## 8. Content safety

Enable Gemini **safety settings** for harassment, hate, dangerous content.  
Chat moderation tool escalates to `app_notifications` + admin queue on high severity.

---

## 9. Nigeria NDPA alignment (practical)

- **Lawful basis:** contract + legitimate interest for fraud/safety  
- **Automated decision-making:** KYC remains human-final; document in runner onboarding  
- **Data subject requests:** export/delete includes `ai_messages` where PII exists  
- **Cross-border:** disclose if Gemini processing outside Nigeria (Vertex region choice)  

---

## 10. Incident response

| Event | Action |
|-------|--------|
| Model outputs harmful instruction | Disable agent feature flag; postmortem |
| Wrong refund proposed | Fix proposal logic; notify user |
| KYC false approve attempt | Verify officer UI not wired to AI |
| Key leak | Rotate `GEMINI_API_KEY`; audit access logs |

Feature flag: `config('ai.agent_enabled')` per environment.

---

## 11. Security review checklist (before prod)

- [ ] All tools have PHPUnit policy tests  
- [ ] Pen test on `POST /api/ai/confirm` replay  
- [ ] No R4 tools in registry  
- [ ] S3 URLs are short-lived pre-signed  
- [ ] Admin tools require `role:admin` middleware  
- [ ] Grounding pack version pinned  
