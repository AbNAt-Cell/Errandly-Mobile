<?php

namespace App\Events;

use App\Models\Errand;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class RunnerAssigned implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Errand $errand) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("customer.{$this->errand->customer_id}"),
            new PrivateChannel("errand.{$this->errand->id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'runner.assigned';
    }

    public function broadcastWith(): array
    {
        return [
            'errand_id' => $this->errand->id,
            'runner' => [
                'id' => $this->errand->runner?->id,
                'name' => $this->errand->runner?->full_name,
            ],
        ];
    }
}
