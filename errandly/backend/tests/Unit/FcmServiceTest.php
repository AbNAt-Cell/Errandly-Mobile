<?php

namespace Tests\Unit;

use App\Services\FcmService;
use Tests\TestCase;

class FcmServiceTest extends TestCase
{
    public function test_normalize_data_casts_values_to_strings(): void
    {
        $fcm = new FcmService;

        $normalized = $fcm->normalizeData([
            'type' => 'errand_offer',
            'errand_id' => 42,
            'budget' => 5000,
            'meta' => ['foo' => 'bar'],
            'nullable' => null,
        ]);

        $this->assertSame([
            'type' => 'errand_offer',
            'errand_id' => '42',
            'budget' => '5000',
            'meta' => '{"foo":"bar"}',
            'nullable' => '',
        ], $normalized);
    }
}
