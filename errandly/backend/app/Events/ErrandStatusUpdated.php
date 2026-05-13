<?php

namespace App\Events;

use App\Models\Errand;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ErrandStatusUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Errand $errand) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("errand.{$this->errand->id}"),
            new PrivateChannel("customer.{$this->errand->customer_id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'errand.status.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'errand_id' => $this->errand->id,
            'status' => $this->errand->status,
            'updated_at' => $this->errand->updated_at->toIso8601String(),
        ];
    }
}
