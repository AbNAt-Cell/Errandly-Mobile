<?php

namespace App\Jobs;

use App\Models\Message;
use App\Services\Ai\MessageModerationScanner;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ScanMessageModerationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $messageId) {}

    public function handle(MessageModerationScanner $scanner): void
    {
        if (!config('ai.features.chat_moderation')) {
            return;
        }

        $message = Message::find($this->messageId);
        if ($message && !$message->is_system) {
            $scanner->scan($message);
        }
    }
}
