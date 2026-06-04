<?php

return [

    'agent_enabled' => env('AI_AGENT_ENABLED', true),

    'fake_responses' => env('AI_FAKE_RESPONSES', env('APP_ENV') === 'testing' || empty(env('GEMINI_API_KEY'))),

    'models' => [
        'agent' => env('GEMINI_MODEL_AGENT', 'gemini-2.0-flash'),
        'vision' => env('GEMINI_MODEL_VISION', 'gemini-2.0-flash'),
        'embedding' => env('GEMINI_MODEL_EMBEDDING', 'text-embedding-004'),
    ],

    'api_key' => env('GEMINI_API_KEY'),
    'api_base' => env('GEMINI_API_BASE', 'https://generativelanguage.googleapis.com/v1beta'),

    'max_tool_iterations' => (int) env('AI_MAX_TOOL_ITERATIONS', 8),

    'grounding_version' => '2026-05-17',

    'proposal_ttl_seconds' => (int) env('AI_PROPOSAL_TTL_SECONDS', 300),

    'rate_limits' => [
        'agent_per_hour' => (int) env('AI_AGENT_RATE_LIMIT', 60),
    ],

    'features' => [
        'errand_parse' => env('AI_ERRAND_PARSE_ENABLED', true),
        'proof_scan' => env('AI_PROOF_SCAN_ENABLED', true),
        'kyc_assist' => env('AI_KYC_ASSIST_ENABLED', true),
        'policy_search' => env('AI_POLICY_SEARCH_ENABLED', true),
        'dispute_copilot' => env('AI_DISPUTE_COPILOT_ENABLED', true),
        'dispute_classifier' => env('AI_DISPUTE_CLASSIFIER_ENABLED', true),
        'chat_moderation' => env('AI_CHAT_MODERATION_ENABLED', true),
        'panic_triage' => env('AI_PANIC_TRIAGE_ENABLED', true),
        'budget_suggest' => env('AI_BUDGET_SUGGEST_ENABLED', true),
        'address_normalize' => env('AI_ADDRESS_NORMALIZE_ENABLED', true),
        'gps_proof_check' => env('AI_GPS_PROOF_CHECK_ENABLED', true),
        'fraud_radar' => env('AI_FRAUD_RADAR_ENABLED', true),
    ],

    'gps_proof_threshold_km' => (float) env('AI_GPS_PROOF_THRESHOLD_KM', 2.0),

    'ingest_paths' => [
        'policy' => [
            base_path('../docs/ai/01-system-context-for-gemini.md'),
            base_path('../docs/README.md'),
        ],
    ],

];
