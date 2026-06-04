# F05 — Intelligent KYC Assist

**Modality:** Vision + text extraction  
**Users:** Verification officers (output); runners (input only)

---

## 1. Purpose

Accelerate runner onboarding by pre-processing:
- Government ID (NIN card, license, passport, voter card)
- Selfie / live photo
- Address proof

Deliver **recommendations and flags** — not approvals.

---

## 2. Trigger

```php
KycSubmitted::class → AnalyzeKycSubmissionJob
```

Runs when runner submits via `POST /api/runner/kyc/submit` or `POST /api/kyc/submit`.

---

## 3. Pipeline

```text
1. Load kyc_documents row + S3 URLs
2. Gemini Vision: OCR ID fields, detect blur/glare
3. Face comparison: selfie vs ID photo (Gemini or dedicated face API)
4. Cross-check NIN/BVN format (checksum rules in PHP, not AI)
5. Duplicate detection: hash face embedding / id number vs DB
6. Write ai_vision_analyses + kyc_documents.officer_summary
7. Set queue priority score for admin UI
```

---

## 4. Output schema

```json
{
  "id_extracted": {
    "full_name": "string",
    "id_number_masked": "****1234",
    "expiry_date": "YYYY-MM-DD|null"
  },
  "face_match_score": 0.92,
  "document_quality": "good|poor",
  "flags": [
    { "code": "NAME_MISMATCH", "severity": "high" },
    { "code": "DOCUMENT_EXPIRED", "severity": "high" }
  ],
  "recommendation": "review|likely_approve|likely_reject",
  "officer_summary": "Paragraph for human reviewer."
}
```

**`recommendation` is advisory only** — UI label: “AI suggestion, not a decision.”

---

## 5. Officer UI (`admin/kyc`)

| Element | Source |
|---------|--------|
| Risk badge | `recommendation` + max severity |
| Side panel | `officer_summary` |
| Extracted fields | pre-fill review form (officer verifies) |
| Approve/Reject | Existing `AdminKycController` — **no AI hook** |

---

## 6. Data handling

- Do not send full NIN/BVN to Gemini if avoidable; OCR on server redacts before log  
- Retain analysis 30 days; ID images follow existing S3 lifecycle  
- Document in privacy policy: automated assist + human decision  

---

## 7. Agent tools

| Tool | Who |
|------|-----|
| `analyze_kyc_submission` | Admin/officer (on demand) |
| `get_kyc_status` | Runner (read own status only) |

Runner asks agent: “Why was I rejected?” → read status + `resubmission_notes` — **no** internal flags unless policy allows friendly explanation.

---

## 8. Compliance

- NDPA: human final decision on access to work  
- Avoid bias: periodic audit of false reject/approve rates by demographic proxy  
- Age verification if DOB extracted — flag only  

---

## 9. Tasks

- [ ] `KycDocumentAnalyzer`  
- [ ] `kyc_documents.ai_analysis` JSON  
- [ ] Admin KYC page badges  
- [ ] Face match: evaluate Gemini vs Cloud Vision Face  
- [ ] Tests with synthetic/redacted ID fixtures  

---

## 10. Future

- Liveness video (blink) — separate vendor or Gemini video understanding  
- NIMC API integration for NIN verify (non-Gemini)  
