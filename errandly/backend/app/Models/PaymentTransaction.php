<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentTransaction extends Model
{
    const TYPE_WALLET_FUNDING = 'wallet_funding';
    const TYPE_PAYOUT         = 'payout';
    const TYPE_REFUND         = 'refund';

    const STATUS_PENDING    = 'pending';
    const STATUS_PROCESSING = 'processing';
    const STATUS_SUCCESS    = 'success';
    const STATUS_FAILED     = 'failed';
    const STATUS_REFUNDED   = 'refunded';

    protected $fillable = [
        'user_id',
        'type',
        'gateway',
        'reference',
        'gateway_reference',
        'amount',
        'currency',
        'status',
        'gateway_response',
        'metadata',
        'processed_at',
    ];

    protected $casts = [
        'gateway_response' => 'array',
        'metadata'         => 'array',
        'processed_at'     => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isPending(): bool   { return $this->status === self::STATUS_PENDING; }
    public function isSuccess(): bool   { return $this->status === self::STATUS_SUCCESS; }
    public function isFailed(): bool    { return $this->status === self::STATUS_FAILED; }
    public function isPayout(): bool    { return $this->type === self::TYPE_PAYOUT; }
    public function isFunding(): bool   { return $this->type === self::TYPE_WALLET_FUNDING; }
}
