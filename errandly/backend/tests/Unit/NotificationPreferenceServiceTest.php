<?php

namespace Tests\Unit;

use App\Models\AppNotification;
use App\Services\NotificationPreferenceService;
use Tests\TestCase;

class NotificationPreferenceServiceTest extends TestCase
{
    public function test_category_mapping_for_errand_and_marketing_types(): void
    {
        $service = new NotificationPreferenceService;

        $this->assertSame('errand_updates', $service->categoryForType(AppNotification::TYPE_ERRAND_OFFER));
        $this->assertSame('payments', $service->categoryForType(AppNotification::TYPE_PAYMENT_RELEASED));
        $this->assertSame('marketing', $service->categoryForType(AppNotification::TYPE_ANNOUNCEMENT));
        $this->assertSame('alerts', $service->categoryForType(AppNotification::TYPE_PANIC_ALERT));
    }
}
