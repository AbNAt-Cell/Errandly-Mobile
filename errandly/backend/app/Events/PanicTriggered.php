<?php

namespace App\Events;

use App\Models\Errand;
use App\Models\User;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PanicTriggered implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Errand $errand, public User $triggeredBy) {}

    public function broadcastOn(): array
    {
        return [new Channel('admin.alerts')];
    }

    public function broadcastAs(): string
    {
        return 'panic.triggered';
    }

    public function broadcastWith(): array
    {
        return [
            'errand_id' => $this->errand->id,
            'errand_title' => $this->errand->title,
            'triggered_by' => $this->triggeredBy->full_name,
            'triggered_by_id' => $this->triggeredBy->id,
            'timestamp' => now()->toIso8601String(),
        ];
    }
}
