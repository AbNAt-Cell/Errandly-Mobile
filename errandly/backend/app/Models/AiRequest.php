<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AiRequest extends Model
{
    protected $fillable = [
        'user_id',
        'session_id',
        'feature',
        'model',
        'input_tokens',
        'output_tokens',
        'latency_ms',
        'status',
        'error_code',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function toolCalls(): HasMany
    {
        return $this->hasMany(AiToolCall::class);
    }
}
