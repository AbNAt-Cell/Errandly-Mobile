# Backend Integration (Laravel)

Concrete plan for implementing AI in `errandly/backend/`.

---

## 1. Environment variables

```env
# Gemini
GEMINI_API_KEY=
GEMINI_PROJECT_ID=          # if Vertex
GEMINI_LOCATION=us-central1
GEMINI_MODEL_AGENT=gemini-2.0-flash
GEMINI_MODEL_VISION=gemini-2.0-flash
GEMINI_MODEL_REASONING=gemini-2.5-pro

# Feature flags
AI_AGENT_ENABLED=true
AI_ERRAND_PARSE_ENABLED=true
AI_PROOF_SCAN_ENABLED=true
AI_KYC_ASSIST_ENABLED=true

# Limits
AI_MAX_TOOL_ITERATIONS=8
AI_AGENT_RATE_LIMIT=60
```

---

## 2. Config file `config/ai.php`

```php
return [
    'agent_enabled' => env('AI_AGENT_ENABLED', false),
    'models' => [
        'agent' => env('GEMINI_MODEL_AGENT', 'gemini-2.0-flash'),
        'vision' => env('GEMINI_MODEL_VISION', 'gemini-2.0-flash'),
    ],
    'max_tool_iterations' => (int) env('AI_MAX_TOOL_ITERATIONS', 8),
    'grounding_version' => '2026-05-17',
    'proposal_ttl_seconds' => 300,
];
```

---

## 3. Database migrations

### `ai_sessions`
| Column | Type |
|--------|------|
| id | uuid PK |
| user_id | FK users |
| channel | string |
| metadata | json nullable |
| expires_at | timestamp |
| timestamps | |

### `ai_messages`
| Column | Type |
|--------|------|
| id | bigint PK |
| session_id | uuid FK |
| role | enum: user, model, tool |
| content | text |
| tool_name | string nullable |
| timestamps | |

### `ai_requests`
| Column | Type |
|--------|------|
| id | bigint PK |
| user_id | FK |
| session_id | uuid nullable |
| feature | string (agent, proof_scan, kyc_assist, …) |
| model | string |
| input_tokens | int nullable |
| output_tokens | int nullable |
| latency_ms | int |
| status | enum: success, error |
| error_code | string nullable |
| timestamps | |

### `ai_tool_calls`
| Column | Type |
|--------|------|
| id | bigint PK |
| ai_request_id | FK |
| tool_name | string |
| arguments | json |
| result_ok | boolean |
| result_summary | text nullable |
| timestamps | |

### `ai_proposals`
| Column | Type |
|--------|------|
| id | uuid PK |
| user_id | FK |
| type | string |
| payload | json |
| payload_hash | string |
| status | enum: pending, confirmed, expired, rejected |
| expires_at | timestamp |
| confirmed_at | timestamp nullable |
| executed_reference | string nullable (e.g. errand public_id) |
| timestamps | |

### `ai_vision_analyses`
| Column | Type |
|--------|------|
| id | bigint PK |
| subject_type | string (errand_proof, kyc_document, errand_intake) |
| subject_id | string |
| model | string |
| result | json |
| flags | json |
| timestamps | |

---

## 4. Routes `routes/api.php`

```php
Route::middleware(['auth:sanctum'])->prefix('ai')->group(function () {
    Route::post('/agent', [AiAgentController::class, 'chat']);
    Route::post('/confirm', [AiAgentController::class, 'confirmProposal']);
    Route::get('/sessions', [AiAgentController::class, 'sessions']);
    Route::get('/sessions/{session}', [AiAgentController::class, 'history']);

    // Standalone (optional direct client calls)
    Route::post('/errands/parse-text', [AiErrandController::class, 'parseText']);
    Route::post('/errands/parse-image', [AiErrandController::class, 'parseImage']);
    Route::post('/errands/suggest-budget', [AiErrandController::class, 'suggestBudget']);

    Route::middleware(['role:admin|verification_officer'])->group(function () {
        Route::post('/disputes/{dispute}/summarize', [AiDisputeController::class, 'summarize']);
        Route::get('/kyc/{kyc}/analysis', [AiKycController::class, 'show']);
    });
});

// Internal: proof scan triggered after runner uploads proof
// App\Listeners\AnalyzeProofSubmission → job
```

---

## 5. Service layout

```
app/Services/Ai/
├── GeminiClient.php
├── AiAgentService.php
├── AiGroundingBuilder.php
├── AiProposalService.php
├── AiToolRegistry.php
├── AiToolExecutor.php
├── Tools/
│   ├── GetMyErrandsTool.php
│   ├── GetErrandTool.php
│   ├── ProposeCreateErrandTool.php
│   └── ...
└── Vision/
    ├── ErrandIntakeAnalyzer.php
    ├── ProofAnalyzer.php
    └── KycDocumentAnalyzer.php
```

---

## 6. `AiToolExecutor` (core safety)

```php
public function execute(User $user, string $name, array $args): array
{
    $def = $this->registry->get($name);

    if (!$def->allowsRole($user)) {
        return $this->fail('FORBIDDEN', 'Tool not available for your role.');
    }

    if ($def->tier === ToolTier::ConfirmWrite) {
        return $this->fail('CONFIRMATION_REQUIRED', 'Use confirm endpoint.');
    }

    $this->audit->toolStarted($user, $name, $args);

    try {
        $result = $def->handler->handle($user, $args);
        $this->audit->toolFinished($name, true);
        return $this->ok($result);
    } catch (ModelNotFoundException) {
        return $this->fail('NOT_FOUND', 'Resource not found.');
    }
}
```

Handlers call **existing** services:

```php
// ProposeCreateErrandTool — validates like ErrandController::store
$validated = Validator::make($args, [...])->validate();
return $this->proposals->create($user, 'create_errand', $validated);
```

```php
// Confirm — AiProposalService
$proposal = $this->proposals->consume($user, $proposalId, $token);
match ($proposal->type) {
    'create_errand' => $this->errandService->createErrand($user, $proposal->payload),
    ...
};
```

---

## 7. Jobs (async)

| Job | Trigger |
|-----|---------|
| `AnalyzeProofSubmissionJob` | After proof upload |
| `AnalyzeKycSubmissionJob` | After KYC submit |
| `ScanMessageModerationJob` | After message send |
| `ComputeFraudSignalsJob` | Nightly / on escrow events |

---

## 8. Events / listeners

```php
// EventServiceProvider
ProofSubmissionCreated::class => [QueueProofAnalysis::class],
MessageCreated::class => [QueueMessageModeration::class],
KycSubmitted::class => [QueueKycAnalysis::class],
```

---

## 9. Testing

```
tests/Feature/Ai/
├── AgentChatTest.php
├── ToolAuthorizationTest.php
├── ProposalConfirmTest.php
├── ProofAnalysisTest.php
└── KycAnalysisTest.php
```

Mock `GeminiClient` interface in tests; never hit live API in CI.

---

## 10. README update

Add to `errandly/docs/README.md` index:

```markdown
| [ai/README.md](./ai/README.md) | Gemini AI agent, tools, feature plans |
```

---

## 11. Composer dependency

Use official Google client or HTTP + JSON:

```bash
composer require google/cloud-ai-platform  # if Vertex
# or guzzle for REST to generativelanguage.googleapis.com
```

Pin versions in lockfile; document in [08-gemini-configuration.md](./08-gemini-configuration.md).
