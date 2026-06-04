<?php

namespace App\Services\Ai;

use App\Models\AiMessage;
use App\Models\AiRequest;
use App\Models\AiSession;
use App\Models\AiToolCall;
use App\Models\User;
use App\Services\Ai\Contracts\GeminiClientInterface;
use Illuminate\Support\Str;

class AiAgentService
{
    public function __construct(
        private GeminiClientInterface $gemini,
        private AiGroundingBuilder $grounding,
        private AiToolRegistry $registry,
        private AiToolExecutor $executor,
    ) {}

    /**
     * @return array{session_id: string, reply: string, proposals: array, tool_traces: array}
     */
    public function chat(User $user, string $message, ?string $sessionId = null, ?array $context = null): array
    {
        $session = $this->resolveSession($user, $sessionId);
        $this->storeMessage($session, 'user', $message);

        $contents = $this->buildContents($session, $user, $context);
        $tools = $this->registry->toolsForUser($user);
        $model = config('ai.models.agent');
        $proposals = [];
        $toolTraces = [];
        $reply = '';

        $aiRequest = AiRequest::create([
            'user_id' => $user->id,
            'session_id' => $session->id,
            'feature' => 'agent',
            'model' => $model,
            'status' => 'success',
        ]);

        $maxIterations = config('ai.max_tool_iterations', 8);

        for ($i = 0; $i < $maxIterations; $i++) {
            $response = $this->gemini->generateContent($model, $contents, $tools);
            $aiRequest->update([
                'latency_ms' => ($aiRequest->latency_ms ?? 0) + ($response['usage']['latency_ms'] ?? 0),
                'input_tokens' => $response['usage']['prompt_tokens'] ?? null,
                'output_tokens' => $response['usage']['output_tokens'] ?? null,
            ]);

            $functionCalls = $response['contents']['functionCalls'] ?? [];
            if ($functionCalls === []) {
                $reply = $response['contents']['text'] ?? '';
                break;
            }

            $modelParts = [];
            foreach ($functionCalls as $call) {
                $modelParts[] = [
                    'functionCall' => [
                        'name' => $call['name'],
                        'args' => $call['args'],
                    ],
                ];
            }
            $contents[] = ['role' => 'model', 'parts' => $modelParts];

            $responseParts = [];
            foreach ($functionCalls as $call) {
                $result = $this->executor->execute($user, $call['name'], $call['args'] ?? []);
                $toolTraces[] = ['tool' => $call['name'], 'result' => $result];

                AiToolCall::create([
                    'ai_request_id' => $aiRequest->id,
                    'tool_name' => $call['name'],
                    'arguments' => $call['args'] ?? [],
                    'result_ok' => $result['ok'] ?? false,
                    'result_summary' => mb_substr(json_encode($result), 0, 500),
                ]);

                if (($call['name'] === 'propose_create_errand' || $call['name'] === 'propose_cancel_errand') && ($result['ok'] ?? false)) {
                    $proposals[] = $result['data'];
                }

                $responseParts[] = [
                    'functionResponse' => [
                        'name' => $call['name'],
                        'response' => ['result' => $result],
                    ],
                ];
            }

            $contents[] = ['role' => 'user', 'parts' => $responseParts];
        }

        if ($reply === '' && $toolTraces !== []) {
            $reply = 'I completed the requested checks. Review any proposals below to continue.';
        }

        $this->storeMessage($session, 'model', $reply);

        $draft = $this->extractLatestDraft($toolTraces);

        return [
            'session_id' => $session->id,
            'reply' => $reply,
            'draft' => $draft,
            'proposals' => $proposals,
            'tool_traces' => config('app.debug') ? $toolTraces : [],
        ];
    }

    /**
     * @param  array<int, array{tool: string, result: array}>  $toolTraces
     */
    private function extractLatestDraft(array $toolTraces): ?array
    {
        $draft = null;

        foreach ($toolTraces as $trace) {
            if (($trace['tool'] ?? '') !== 'parse_errand_from_text') {
                continue;
            }
            $result = $trace['result'] ?? [];
            if (($result['ok'] ?? false) && isset($result['data']['draft'])) {
                $draft = $result['data']['draft'];
            }
        }

        return $draft;
    }

    private function resolveSession(User $user, ?string $sessionId): AiSession
    {
        if ($sessionId) {
            return AiSession::where('id', $sessionId)->where('user_id', $user->id)->firstOrFail();
        }

        return AiSession::create([
            'user_id' => $user->id,
            'channel' => $user->hasRole('runner') ? 'runner_app' : 'customer_app',
            'expires_at' => now()->addDays(7),
        ]);
    }

    private function storeMessage(AiSession $session, string $role, string $content): void
    {
        AiMessage::create([
            'session_id' => $session->id,
            'role' => $role,
            'content' => $content,
        ]);
    }

  /**
     * @return array<int, array<string, mixed>>
     */
    private function buildContents(AiSession $session, User $user, ?array $context): array
    {
        $contents = [
            [
                'role' => 'user',
                'parts' => [
                    ['text' => $this->grounding->systemInstruction($user, $context)],
                ],
            ],
        ];

        $history = $session->messages()->orderBy('id')->limit(20)->get();
        foreach ($history as $msg) {
            if ($msg->role === 'tool') {
                continue;
            }
            $contents[] = [
                'role' => $msg->role === 'model' ? 'model' : 'user',
                'parts' => [['text' => $msg->content ?? '']],
            ];
        }

        return $contents;
    }
}
