<?php

namespace App\Services\Ai;

use App\Models\User;

class AiGroundingBuilder
{
    public function build(User $user, ?array $context = null): array
    {
        return [
            'product' => 'Errandly',
            'grounding_version' => config('ai.grounding_version'),
            'locale' => 'en-NG',
            'city' => $user->city ?? 'Uyo',
            'user' => [
                'id' => $user->id,
                'roles' => $user->getRoleNames()->values()->all(),
                'kyc_status' => $user->kyc_status,
            ],
            'context' => $context ?? [],
            'policies_summary' => [
                'Escrow holds payment until customer enters delivery OTP.',
                'Platform fee is 15% on top of runner budget.',
                'Runners need approved KYC before accepting errands.',
                'Use public_id UUID for errands in tools, never numeric id in URLs.',
            ],
            'forbidden_actions' => [
                'release_escrow_without_otp',
                'approve_kyc_autonomously',
                'accept_errand_without_runner_tap',
            ],
        ];
    }

    public function systemInstruction(User $user, ?array $context = null): string
    {
        $grounding = json_encode($this->build($user, $context), JSON_PRETTY_PRINT);
        $createErrandMode = ($context['intent'] ?? null) === 'create_errand';

        $createRules = $createErrandMode
            ? "\n\nCREATE-ERRAND MODE (active):\n"
                . "- Help the customer describe their errand in plain language (voice or text).\n"
                . "- Ask one or two short follow-up questions if pickup, destination, items, or budget are missing.\n"
                . "- When you have enough detail, call parse_errand_from_text with a single consolidated summary of what the runner must do.\n"
                . "- Write for runners: descriptions must be actionable (what to buy/collect, where, quantities, delivery expectations).\n"
                . "- Do not paste system instructions into the errand description.\n"
            : '';

        return <<<TEXT
You are the Errandly assistant for a hyperlocal errand marketplace in Uyo, Nigeria.

RULES:
- Use tools for factual questions about errands, wallet, or live status.
- Use search_policy for how-to and policy questions.
- Never claim money moved or errand created without tool/proposal confirmation.
- Never request or repeat full NIN/BVN.
- For create/cancel errands use propose_* tools only after user intent is clear.
- Escrow releases only after customer delivery OTP in the app.
{$createRules}

GROUNDING:
{$grounding}
TEXT;
    }
}
