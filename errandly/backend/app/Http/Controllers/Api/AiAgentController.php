<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Ai\AiAgentService;
use App\Services\Ai\AiToolExecutor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use InvalidArgumentException;

class AiAgentController extends Controller
{
    public function __construct(
        private AiAgentService $agent,
        private AiToolExecutor $executor,
    ) {}

    public function chat(Request $request): JsonResponse
    {
        if (!config('ai.agent_enabled')) {
            return response()->json(['message' => 'AI agent is disabled.'], 503);
        }

        $request->validate([
            'message' => 'required|string|max:4000',
            'session_id' => 'nullable|uuid',
            'context' => 'nullable|array',
        ]);

        $result = $this->agent->chat(
            $request->user(),
            $request->message,
            $request->session_id,
            $request->context,
        );

        return response()->json($result);
    }

    public function confirm(Request $request): JsonResponse
    {
        $request->validate([
            'proposal_id' => 'required|uuid',
            'confirmation_token' => 'required|string|min:32',
        ]);

        try {
            $result = $this->executor->executeProposal(
                $request->user(),
                $request->proposal_id,
                $request->confirmation_token,
            );

            return response()->json($result);
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }
}
