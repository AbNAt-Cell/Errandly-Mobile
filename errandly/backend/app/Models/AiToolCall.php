<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiToolCall extends Model
{
    protected $fillable = [
        'ai_request_id',
        'tool_name',
        'arguments',
        'result_ok',
        'result_summary',
    ];

    protected $casts = [
        'arguments' => 'array',
        'result_ok' => 'boolean',
    ];

    public function request(): BelongsTo
    {
        return $this->belongsTo(AiRequest::class, 'ai_request_id');
    }
}
