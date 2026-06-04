# Gemini Configuration

How to connect Errandly to Google Gemini for agent, vision, and analysis features.

---

## 1. Deployment options

| Option | Pros | Cons |
|--------|------|------|
| **Google AI Studio** (API key) | Fastest dev setup | Key management; region limits |
| **Vertex AI** (GCP) | Enterprise IAM, VPC, billing | More setup |

**Recommendation:** Vertex for production; AI Studio for local dev.

---

## 2. Authentication

### AI Studio
```env
GEMINI_API_KEY=your_key
```
REST: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`

### Vertex AI
```env
GEMINI_PROJECT_ID=errandly-prod
GEMINI_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

Use ADC in Laravel via `google/cloud-ai-platform` or REST with OAuth token.

---

## 3. Models (2026 guidance)

| Use | Model ID | Notes |
|-----|----------|-------|
| Agent + tools | `gemini-2.0-flash` | Function calling, fast |
| Vision intake/proof | `gemini-2.0-flash` | Cost-effective |
| KYC / dispute long docs | `gemini-2.5-pro` | Higher accuracy |

Configure in `config/ai.php`; override per feature.

---

## 4. Function calling setup

Pass tools in `tools` / `tool_config` per [Gemini function calling docs](https://ai.google.dev/gemini-api/docs/function-calling).

```php
$payload = [
    'contents' => $contents,
    'tools' => [
        ['functionDeclarations' => $this->registry->toGeminiSchema()],
    ],
    'toolConfig' => [
        'functionCallingConfig' => [
            'mode' => 'AUTO', // or ANY for forced tool
        ],
    ],
];
```

Loop until `finishReason` is not `TOOL_CALLS` or max iterations.

---

## 5. Structured output (errand parse)

Use **JSON schema** response mode when available:

```php
'generationConfig' => [
    'responseMimeType' => 'application/json',
    'responseSchema' => ErrandDraftSchema::toArray(),
],
```

Fallback: parse JSON from text + validate with Laravel Validator.

### Errand draft schema (minimal)

```json
{
  "title": "string",
  "description": "string",
  "category": "enum",
  "urgency": "standard|urgent|scheduled",
  "pickup_address": "string",
  "pickup_latitude": "number",
  "pickup_longitude": "number",
  "destination_address": "string",
  "destination_latitude": "number",
  "destination_longitude": "number",
  "budget": "integer",
  "item_details": "string|null",
  "special_instructions": "string|null",
  "clarifying_questions": ["string"],
  "confidence": "number"
}
```

---

## 6. Vision requests

Pass image as:
- **File API** upload then reference, or  
- **Inline** base64 (dev only; prefer GCS/S3 URL + fetch server-side)

```php
[
    'inlineData' => [
        'mimeType' => 'image/jpeg',
        'data' => base64_encode($bytes),
    ],
]
```

**Never** send customer ID images to vision models except in KYC-specific jobs with audit.

---

## 7. System instruction template

```text
You are the Errandly assistant for a hyperlocal errand marketplace in Uyo, Nigeria.

RULES:
- Use tools for any factual question about errands, wallet, or status.
- Never claim an action succeeded without a tool result.
- Never request or repeat full NIN/BVN.
- For creating or cancelling errands, use propose_* tools only.
- Escrow releases only after customer OTP; you cannot enter OTP.
- If unsure, ask a clarifying question.

CONTEXT:
{grounding_json}
```

Load static rules from [01-system-context-for-gemini.md](./01-system-context-for-gemini.md).

---

## 8. Cost controls

- Cache grounding static prefix where API supports context caching  
- Truncate message history > 20 turns  
- Downgrade to Flash for R0 reads  
- Batch proof scans off-peak  

Monitor: tokens per feature per day in `ai_requests`.

---

## 9. Local development

```php
// config/ai.php
'fake_responses' => env('AI_FAKE_RESPONSES', false),
```

When `true`, `GeminiClient` returns fixtures from `tests/fixtures/ai/`.

---

## 10. Secrets rotation

- Rotate `GEMINI_API_KEY` quarterly  
- Service account keys: 90-day rotation on Vertex  
- Alert on 401 spike in logs  

---

## 11. Compliance checklist

- [ ] Google Cloud / AI Studio terms accepted  
- [ ] DPA signed if required  
- [ ] Region documented for data processing  
- [ ] Safety filters enabled  
- [ ] No production PII in dev project  
