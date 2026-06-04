<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiMessage extends Model
{
    protected $fillable = [
        'session_id',
        'role',
        'content',
        'tool_name',
        'tool_payload',
    ];

    protected $casts = [
        'tool_payload' => 'array',
    ];

    public function session(): BelongsTo
    {
        return $this->belongsTo(AiSession::class, 'session_id');
    }
}
