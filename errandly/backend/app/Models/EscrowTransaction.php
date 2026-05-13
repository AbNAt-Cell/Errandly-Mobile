<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class EscrowTransaction extends Model
{
    use HasFactory, LogsActivity;

    protected $fillable = [
        'errand_id',
        'customer_id',
        'runner_id',
        'total_amount',
        'runner_amount',
        'platform_fee',
        'status',
        'funded_at',
        'released_at',
        'refunded_at',
        'frozen_at',
        'frozen_reason',
        'release_reason',
        'refund_reason',
        'payment_method',
        'payment_reference',
        'gateway_response',
    ];

    protected $casts = [
        'total_amount' => 'integer',
        'runner_amount' => 'integer',
        'platform_fee' => 'integer',
        'funded_at' => 'datetime',
        'released_at' => 'datetime',
        'refunded_at' => 'datetime',
        'frozen_at' => 'datetime',
        'gateway_response' => 'array',
    ];

    const STATUS_PENDING = 'pending_funding';
    const STATUS_FUNDED = 'funded';
    const STATUS_IN_ESCROW = 'in_escrow';
    const STATUS_RELEASED = 'released';
    const STATUS_REFUNDED = 'refunded';
    const STATUS_FROZEN = 'frozen';

    public function errand()
    {
        return $this->belongsTo(Errand::class);
    }

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function runner()
    {
        return $this->belongsTo(User::class, 'runner_id');
    }

    public function isFrozen(): bool
    {
        return $this->status === self::STATUS_FROZEN;
    }

    public function canRelease(): bool
    {
        return $this->status === self::STATUS_IN_ESCROW;
    }

    public function canRefund(): bool
    {
        return in_array($this->status, [self::STATUS_IN_ESCROW, self::STATUS_FROZEN]);
    }

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['status'])
            ->logOnlyDirty();
    }
}
