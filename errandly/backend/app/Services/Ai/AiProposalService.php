<?php

namespace App\Services\Ai;

use App\Models\AiProposal;
use App\Models\User;
use Illuminate\Support\Str;
use InvalidArgumentException;

class AiProposalService
{
    public function createWithToken(User $user, string $type, array $payload): array
    {
        $plainToken = Str::random(48);
        $hash = hash('sha256', json_encode($this->canonicalize($payload)));

        $proposal = AiProposal::create([
            'user_id' => $user->id,
            'type' => $type,
            'payload' => $payload,
            'payload_hash' => $hash,
            'status' => 'pending',
            'confirmation_token' => hash('sha256', $plainToken),
            'expires_at' => now()->addSeconds(config('ai.proposal_ttl_seconds', 300)),
        ]);

        return [
            'proposal' => $proposal,
            'confirmation_token' => $plainToken,
        ];
    }

    public function consume(User $user, string $proposalId, string $plainToken): AiProposal
    {
        $proposal = AiProposal::where('id', $proposalId)
            ->where('user_id', $user->id)
            ->firstOrFail();

        if ($proposal->status !== 'pending') {
            throw new InvalidArgumentException('Proposal is no longer pending.');
        }

        if ($proposal->isExpired()) {
            $proposal->update(['status' => 'expired']);
            throw new InvalidArgumentException('Proposal has expired.');
        }

        if (!hash_equals($proposal->confirmation_token, hash('sha256', $plainToken))) {
            throw new InvalidArgumentException('Invalid confirmation token.');
        }

        $proposal->update([
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);

        return $proposal->fresh();
    }

    private function canonicalize(array $payload): array
    {
        ksort($payload);

        return $payload;
    }
}
