<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class AiProposal extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'user_id',
        'type',
        'payload',
        'payload_hash',
        'status',
        'confirmation_token',
        'expires_at',
        'confirmed_at',
        'executed_reference',
    ];

    protected $casts = [
        'payload' => 'array',
        'expires_at' => 'datetime',
        'confirmed_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (AiProposal $proposal) {
            if (empty($proposal->id)) {
                $proposal->id = (string) Str::uuid();
            }
        });
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }
}
