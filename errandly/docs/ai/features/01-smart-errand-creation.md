# F01 / F02 / F07 / F08 — Smart Errand Creation

**Features:** Vision intake, natural-language text, budget/ETA suggest, address normalization  
**Priority:** P0 (intake), P1 (budget/address)

---

## 1. User stories

| As a | I want to | So that |
|------|-----------|---------|
| Customer | Upload a photo of a list or item | I don’t type long descriptions |
| Customer | Say what I need in one sentence | Posting is faster |
| Customer | Get a suggested budget | Runners accept my errand |
| Customer | Confirm landmark addresses on a map | Pickup/delivery are correct |

---

## 2. UX flows

### 2.1 Vision intake (create errand screen)

1. Customer taps **“Scan list or item”** on `customer/errands/new`.
2. Client uploads image → S3 → `POST /api/ai/errands/parse-image` `{ image_url }`.
3. Server returns **draft** + `clarifying_questions[]`.
4. Form pre-fills; user edits map pins and budget.
5. User taps **Post Errand** → normal `POST /api/customer/errands` (not AI).

### 2.2 Agent path

1. User: “Buy Peak milk and bread from Shoprite, deliver to my house in Ewet.”
2. Agent calls `parse_errand_from_text` → `propose_create_errand`.
3. UI card shows summary + **Confirm & Post**.
4. `POST /api/ai/confirm` → creates errand.

---

## 3. API endpoints

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/ai/errands/parse-text` | Standalone NL parse |
| POST | `/api/ai/errands/parse-image` | Standalone vision parse |
| POST | `/api/ai/errands/suggest-budget` | Budget + duration band |
| POST | `/api/ai/address/normalize` | Landmark → candidates |

Agent tools: `parse_errand_from_text`, `parse_errand_from_image`, `propose_create_errand`, `suggest_budget_and_eta`, `normalize_address`.

---

## 4. Vision prompt strategy

**Input:** image + city=Uyo + min_budget=500

**Extract:**
- Item names, quantities, brands
- Store name if visible
- Deadlines if handwritten
- Category inference

**Output:** JSON per [08-gemini-configuration.md](../08-gemini-configuration.md) schema.

**Guardrails:**
- If unreadable → `clarifying_questions` + low confidence
- Never invent GPS — leave lat/lng null until geocoder or user pin

---

## 5. Geocoding integration

After text parse:
1. Call internal geocoder (Google Maps / Mapbox) for `pickup_address` / `destination_address`.
2. Validate point inside `service_areas` polygon.
3. If outside → warning in proposal.

---

## 6. Budget suggestion logic

```text
base = category_base_fee[category]
distance_km = haversine(pickup, dest)
time_factor = urgency_multiplier[urgency]
suggested_budget = base + (distance_km * per_km_rate)
platform_fee = ceil(suggested_budget * 0.15)
```

Gemini adds natural language: *“Similar grocery runs in Uyo last week averaged ₦1,800–₦2,500.”*

---

## 7. Implementation tasks

### Backend
- [ ] `ErrandIntakeAnalyzer` service  
- [ ] `AiErrandController`  
- [ ] Validator mirroring `ErrandController::store`  
- [ ] `propose_create_errand` tool + confirm handler  
- [ ] Store analysis in `ai_vision_analyses` (optional)

### Web (`create_errand` page)
- [ ] Image upload + loading state  
- [ ] Apply draft to react-hook-form  
- [ ] Clarifying questions UI  

### Mobile (`create_errand_screen.dart`)
- [ ] Camera/gallery → parse-image  
- [ ] Same draft mapping  

### Tests
- [ ] Fixture images: grocery list, blurry, non-list  
- [ ] Validator rejects sub-min budget  

---

## 8. Metrics

- % creates using vision/NL  
- Time to submit (start → post)  
- Edit rate per prefilled field  
- Errand acceptance rate vs non-AI creates  

---

## 9. Safety

- No auto-post without confirm  
- No payment until user posts errand  
- Image URLs expire; don’t log base64  
