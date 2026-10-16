<?php

namespace App\Events;

use App\Models\Errand;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ErrandCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Errand $errand) {}

    public function broadcastOn(): array
    {
        return [
            new Channel('admin.errands'),
            new Channel('errands.available'),
            new Channel("errand.{$this->errand->id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'ErrandCreated';
    }

    public function broadcastWith(): array
    {
        return [
            'errand_id' => $this->errand->id,
            'public_id' => $this->errand->public_id,
            'title' => $this->errand->title,
            'category' => $this->errand->category,
            'budget' => (float) $this->errand->budget,
            'status' => $this->errand->status,
            'pickup_address' => $this->errand->pickup_address,
            'dropoff_address' => $this->errand->dropoff_address,
            'pickup_latitude' => $this->errand->pickup_latitude,
            'pickup_longitude' => $this->errand->pickup_longitude,
            'customer' => [
                'id' => $this->errand->customer?->id,
                'name' => $this->errand->customer?->full_name,
            ],
            'created_at' => $this->errand->created_at?->toIso8601String() ?? now()->toIso8601String(),
        ];
    }
}
