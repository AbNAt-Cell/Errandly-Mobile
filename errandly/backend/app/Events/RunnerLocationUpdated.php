<?php

namespace App\Events;

use App\Models\Errand;
use App\Models\User;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class RunnerLocationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Errand $errand,
        public User $runner,
        public float $latitude,
        public float $longitude,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("errand.{$this->errand->id}"),
            new PrivateChannel("customer.{$this->errand->customer_id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'runner.location.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'errand_id' => $this->errand->id,
            'runner_id' => $this->runner->id,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'timestamp' => now()->toIso8601String(),
        ];
    }
}
