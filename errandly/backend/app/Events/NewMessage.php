<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NewMessage implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Message $message) {}

    public function broadcastOn(): array
    {
        $errand = $this->message->errand;
        return [
            new PrivateChannel("errand.{$errand->id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'new.message';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->message->id,
            'errand_id' => $this->message->errand_id,
            'sender_id' => $this->message->sender_id,
            'type' => $this->message->type,
            'content' => $this->message->content,
            'media_url' => $this->message->media_url,
            'created_at' => $this->message->created_at->toIso8601String(),
        ];
    }
}
