<?php

namespace App\Services\Ai;

/**
 * Cleans model output so descriptions are runner-ready, not leaked prompts.
 */
class ErrandDraftNormalizer
{
    private const PROMPT_MARKERS = [
        'return json',
        'parse this errand',
        'extract errand details',
        'shopping list, item photo',
        'clarifying_questions array',
        'suggested budget in ngn',
        'errandly marketplace',
    ];

    public function normalize(array $draft, ?string $sourceText = null, ?string $notes = null): array
    {
        $draft = array_filter($draft, fn ($v) => $v !== null && $v !== '');

        $title = trim((string) ($draft['title'] ?? ''));
        $description = trim((string) ($draft['description'] ?? ''));
        $itemDetails = trim((string) ($draft['item_details'] ?? ($draft['items'] ?? '')));
        $category = (string) ($draft['category'] ?? 'custom_errand');

        if ($this->looksLikePromptLeak($description)) {
            $description = '';
        }

        if ($description === '' && $sourceText && !$this->looksLikePromptLeak($sourceText)) {
            $description = $this->descriptionFromCustomerRequest($sourceText, $category);
        }

        if ($description === '' && $notes) {
            $description = $this->descriptionFromCustomerRequest($notes, $category);
        }

        if ($description === '' && $itemDetails !== '') {
            $description = $this->descriptionFromItems($itemDetails, $draft, $category);
        }

        if ($description === '') {
            $description = $this->fallbackRunnerDescription($draft, $category);
        }

        $draft['description'] = $description;
        $draft['title'] = $title !== '' ? $title : $this->titleFromCategory($category);
        $draft['item_details'] = $itemDetails !== '' ? $itemDetails : null;

        if (!isset($draft['clarifying_questions']) || !is_array($draft['clarifying_questions'])) {
            $draft['clarifying_questions'] = [];
        }

        return $draft;
    }

    private function looksLikePromptLeak(string $text): bool
    {
        $lower = strtolower($text);
        if (strlen($text) < 12) {
            return false;
        }

        foreach (self::PROMPT_MARKERS as $marker) {
            if (str_contains($lower, $marker)) {
                return true;
            }
        }

        return str_contains($text, 'JSON with') || str_contains($text, 'array.');
    }

    private function descriptionFromCustomerRequest(string $request, string $category): string
    {
        $pickup = 'the pickup location shown in the app';
        $dest = 'the delivery address shown in the app';

        return match ($category) {
            'grocery_purchase', 'shopping_assistance' => "Purchase exactly what the customer requested: {$request}. Shop at the pickup store, keep the receipt, and deliver all items to {$dest}. Message the customer in-app if anything is unavailable or needs a substitution.",
            'package_pickup', 'item_delivery' => "Collect the package or items described: {$request}. Pick up at {$pickup} and deliver safely to {$dest}. Handle with care and confirm delivery details with the customer in-app if needed.",
            'prescription_pickup' => "Pick up the prescription or pharmacy items as requested: {$request}. Follow pharmacy rules, keep the receipt, and deliver to {$dest}. Do not open sealed medical packaging unless the customer instructs you.",
            default => "Complete this errand for the customer: {$request}. Start at {$pickup}, follow any special instructions, and finish at {$dest}. Use in-app chat for quick questions.",
        };
    }

    private function descriptionFromItems(string $items, array $draft, string $category): string
    {
        $store = trim((string) ($draft['pickup_address'] ?? 'the pickup store'));
        $dest = trim((string) ($draft['destination_address'] ?? 'the delivery address'));

        $action = match ($category) {
            'grocery_purchase', 'shopping_assistance' => "Go to {$store} and buy the following items",
            'prescription_pickup' => "Go to {$store} and collect the following",
            default => "At {$store}, complete the following",
        };

        return "{$action}:\n{$items}\n\nKeep the receipt. Deliver everything to {$dest}. Contact the customer in-app if any item is unavailable.";
    }

    private function fallbackRunnerDescription(array $draft, string $category): string
    {
        $store = trim((string) ($draft['pickup_address'] ?? 'the pickup location'));
        $dest = trim((string) ($draft['destination_address'] ?? 'the destination'));

        return match ($category) {
            'grocery_purchase' => "Buy the listed groceries at {$store}, keep the receipt, and deliver to {$dest}.",
            'package_pickup' => "Pick up the package at {$store} and deliver to {$dest}.",
            default => "Complete the customer's errand from {$store} to {$dest}. Follow item details and special instructions in the app.",
        };
    }

    private function titleFromCategory(string $category): string
    {
        return match ($category) {
            'grocery_purchase' => 'Grocery purchase',
            'package_pickup' => 'Package pickup',
            'item_delivery' => 'Item delivery',
            'prescription_pickup' => 'Prescription pickup',
            default => 'Custom errand',
        };
    }
}
