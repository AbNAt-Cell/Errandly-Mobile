<?php

namespace App\Services\Ai;

use App\Models\User;

class AiToolRegistry
{
    /** @var array<string, array{tier: ToolTier, roles: array<string>, schema: array, handler: string}> */
    private array $tools = [
        'get_me' => [
            'tier' => ToolTier::Read,
            'roles' => ['customer', 'runner', 'admin', 'super_admin', 'verification_officer'],
            'schema' => [
                'name' => 'get_me',
                'description' => 'Get the authenticated user profile.',
                'parameters' => ['type' => 'object', 'properties' => []],
            ],
        ],
        'get_my_errands' => [
            'tier' => ToolTier::Read,
            'roles' => ['customer', 'runner', 'admin', 'super_admin'],
            'schema' => [
                'name' => 'get_my_errands',
                'description' => 'List errands for the current user.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'status' => ['type' => 'string'],
                        'limit' => ['type' => 'integer'],
                    ],
                ],
            ],
        ],
        'get_errand' => [
            'tier' => ToolTier::Read,
            'roles' => ['customer', 'runner', 'admin', 'super_admin', 'verification_officer'],
            'schema' => [
                'name' => 'get_errand',
                'description' => 'Get one errand by public_id UUID.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'public_id' => ['type' => 'string'],
                    ],
                    'required' => ['public_id'],
                ],
            ],
        ],
        'search_policy' => [
            'tier' => ToolTier::Read,
            'roles' => ['customer', 'runner', 'admin', 'super_admin', 'verification_officer'],
            'schema' => [
                'name' => 'search_policy',
                'description' => 'Search Errandly policies and help docs.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'query' => ['type' => 'string'],
                        'limit' => ['type' => 'integer'],
                    ],
                    'required' => ['query'],
                ],
            ],
        ],
        'parse_errand_from_text' => [
            'tier' => ToolTier::Analyze,
            'roles' => ['customer'],
            'schema' => [
                'name' => 'parse_errand_from_text',
                'description' => 'Parse natural language into a draft errand.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'text' => ['type' => 'string'],
                    ],
                    'required' => ['text'],
                ],
            ],
        ],
        'propose_create_errand' => [
            'tier' => ToolTier::Propose,
            'roles' => ['customer'],
            'schema' => [
                'name' => 'propose_create_errand',
                'description' => 'Propose creating an errand (requires user confirmation).',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'title' => ['type' => 'string'],
                        'description' => ['type' => 'string'],
                        'category' => ['type' => 'string'],
                        'pickup_address' => ['type' => 'string'],
                        'pickup_latitude' => ['type' => 'number'],
                        'pickup_longitude' => ['type' => 'number'],
                        'destination_address' => ['type' => 'string'],
                        'destination_latitude' => ['type' => 'number'],
                        'destination_longitude' => ['type' => 'number'],
                        'budget' => ['type' => 'integer'],
                        'urgency' => ['type' => 'string'],
                        'item_details' => ['type' => 'string'],
                        'special_instructions' => ['type' => 'string'],
                    ],
                    'required' => ['title', 'description', 'category', 'pickup_address', 'pickup_latitude', 'pickup_longitude', 'destination_address', 'destination_latitude', 'destination_longitude', 'budget'],
                ],
            ],
        ],
        'propose_cancel_errand' => [
            'tier' => ToolTier::Propose,
            'roles' => ['customer', 'runner'],
            'schema' => [
                'name' => 'propose_cancel_errand',
                'description' => 'Propose cancelling an errand (requires confirmation).',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'public_id' => ['type' => 'string'],
                        'reason' => ['type' => 'string'],
                    ],
                    'required' => ['public_id', 'reason'],
                ],
            ],
        ],
        'suggest_budget_and_eta' => [
            'tier' => ToolTier::Analyze,
            'roles' => ['customer'],
            'schema' => [
                'name' => 'suggest_budget_and_eta',
                'description' => 'Suggest budget and ETA for an errand from category and coordinates.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'category' => ['type' => 'string'],
                        'pickup_latitude' => ['type' => 'number'],
                        'pickup_longitude' => ['type' => 'number'],
                        'destination_latitude' => ['type' => 'number'],
                        'destination_longitude' => ['type' => 'number'],
                        'urgency' => ['type' => 'string'],
                    ],
                    'required' => ['category', 'pickup_latitude', 'pickup_longitude', 'destination_latitude', 'destination_longitude'],
                ],
            ],
        ],
        'normalize_address' => [
            'tier' => ToolTier::Analyze,
            'roles' => ['customer', 'runner'],
            'schema' => [
                'name' => 'normalize_address',
                'description' => 'Normalize free-text address or landmark to coordinates.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'free_text' => ['type' => 'string'],
                        'city' => ['type' => 'string'],
                    ],
                    'required' => ['free_text'],
                ],
            ],
        ],
        'suggest_errand_template' => [
            'tier' => ToolTier::Analyze,
            'roles' => ['customer'],
            'schema' => [
                'name' => 'suggest_errand_template',
                'description' => 'Suggest errand templates from past completed errands.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'hint' => ['type' => 'string'],
                    ],
                ],
            ],
        ],
        'explain_trust_score' => [
            'tier' => ToolTier::Read,
            'roles' => ['runner'],
            'schema' => [
                'name' => 'explain_trust_score',
                'description' => 'Explain the runner trust score breakdown.',
                'parameters' => ['type' => 'object', 'properties' => []],
            ],
        ],
        'list_available_errands' => [
            'tier' => ToolTier::Read,
            'roles' => ['runner'],
            'schema' => [
                'name' => 'list_available_errands',
                'description' => 'List posted errands available near the runner.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'limit' => ['type' => 'integer'],
                    ],
                ],
            ],
        ],
        'summarize_dispute' => [
            'tier' => ToolTier::Analyze,
            'roles' => ['admin', 'super_admin', 'verification_officer'],
            'schema' => [
                'name' => 'summarize_dispute',
                'description' => 'Generate AI dispute summary for admins.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'dispute_id' => ['type' => 'integer'],
                    ],
                    'required' => ['dispute_id'],
                ],
            ],
        ],
        'admin_report_errands' => [
            'tier' => ToolTier::Read,
            'roles' => ['admin', 'super_admin'],
            'schema' => [
                'name' => 'admin_report_errands',
                'description' => 'Get errand volume stats for a period.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'period' => ['type' => 'string'],
                    ],
                ],
            ],
        ],
    ];

    public function toolsForUser(User $user): array
    {
        $roles = $user->getRoleNames()->all();
        $declarations = [];

        foreach ($this->tools as $name => $tool) {
            if ($this->allowsRole($tool['roles'], $roles)) {
                $declarations[] = $tool['schema'];
            }
        }

        return $declarations;
    }

    public function get(string $name): ?array
    {
        return $this->tools[$name] ?? null;
    }

    public function tier(string $name): ?ToolTier
    {
        return $this->tools[$name]['tier'] ?? null;
    }

    public function allows(User $user, string $name): bool
    {
        $tool = $this->get($name);
        if ($tool === null) {
            return false;
        }

        return $this->allowsRole($tool['roles'], $user->getRoleNames()->all());
    }

    private function allowsRole(array $allowed, array $userRoles): bool
    {
        return count(array_intersect($allowed, $userRoles)) > 0;
    }
}
