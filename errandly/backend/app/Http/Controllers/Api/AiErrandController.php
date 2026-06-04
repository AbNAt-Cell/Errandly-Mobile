<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Ai\AddressNormalizer;
use App\Services\Ai\AiProposalService;
use App\Services\Ai\AiToolExecutor;
use App\Services\Ai\BudgetEtaSuggester;
use App\Services\Ai\ErrandTemplateSuggester;
use App\Services\Ai\Vision\ErrandIntakeAnalyzer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use InvalidArgumentException;

class AiErrandController extends Controller
{
    public function __construct(
        private ErrandIntakeAnalyzer $intake,
        private AiProposalService $proposals,
        private AiToolExecutor $executor,
        private BudgetEtaSuggester $budgetEta,
        private AddressNormalizer $addressNormalizer,
        private ErrandTemplateSuggester $templateSuggester,
    ) {}

    public function parseText(Request $request): JsonResponse
    {
        if (!config('ai.features.errand_parse')) {
            return response()->json(['message' => 'Feature disabled.'], 503);
        }

        $request->validate(['text' => 'required|string|max:4000']);

        $draft = $this->intake->parseText($request->text);

        return response()->json(['draft' => $draft]);
    }

    public function parseImage(Request $request): JsonResponse
    {
        if (!config('ai.features.errand_parse')) {
            return response()->json(['message' => 'Feature disabled.'], 503);
        }

        $request->validate([
            'image_url' => [
                'required',
                'string',
                'max:6000000',
                'regex:/^data:image\/(jpeg|jpg|png|webp|gif);base64,/i',
            ],
            'notes' => 'nullable|string|max:1000',
        ]);

        $draft = $this->intake->parseImage($request->image_url, $request->notes);

        return response()->json(['draft' => $draft]);
    }

    public function suggestBudget(Request $request): JsonResponse
    {
        if (config('ai.features.budget_suggest', true) === false) {
            return response()->json(['message' => 'Feature disabled.'], 503);
        }

        $request->validate([
            'category' => 'required|string',
            'pickup_latitude' => 'required|numeric',
            'pickup_longitude' => 'required|numeric',
            'destination_latitude' => 'required|numeric',
            'destination_longitude' => 'required|numeric',
            'urgency' => 'nullable|string',
        ]);

        $suggestion = $this->budgetEta->suggest(
            $request->category,
            (float) $request->pickup_latitude,
            (float) $request->pickup_longitude,
            (float) $request->destination_latitude,
            (float) $request->destination_longitude,
            $request->urgency ?? 'standard',
        );

        return response()->json($suggestion);
    }

    public function normalizeAddress(Request $request): JsonResponse
    {
        if (config('ai.features.address_normalize', true) === false) {
            return response()->json(['message' => 'Feature disabled.'], 503);
        }

        $request->validate([
            'free_text' => 'required|string|max:500',
            'city' => 'nullable|string|max:100',
        ]);

        $result = $this->addressNormalizer->normalize(
            $request->free_text,
            $request->city ?? $request->user()->city ?? 'Uyo',
        );

        return response()->json($result);
    }

    public function suggestTemplate(Request $request): JsonResponse
    {
        $request->validate(['hint' => 'nullable|string|max:200']);

        return response()->json(
            $this->templateSuggester->suggest($request->user(), $request->hint),
        );
    }

    public function proposeCreate(Request $request): JsonResponse
    {
        $result = $this->executor->execute($request->user(), 'propose_create_errand', $request->all());

        if (!($result['ok'] ?? false)) {
            return response()->json(['message' => $result['message'] ?? 'Failed'], 422);
        }

        return response()->json($result['data'], 201);
    }

    public function confirm(Request $request): JsonResponse
    {
        $request->validate([
            'proposal_id' => 'required|uuid',
            'confirmation_token' => 'required|string',
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
