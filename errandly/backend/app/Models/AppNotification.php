<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'body',
        'data',
        'read_at',
        'action_url',
        'icon',
    ];

    protected $casts = [
        'read_at' => 'datetime',
        'data' => 'array',
    ];

    const TYPE_ERRAND_ASSIGNED = 'errand_assigned';
    const TYPE_RUNNER_ARRIVED = 'runner_arrived';
    const TYPE_TASK_STARTED = 'task_started';
    const TYPE_TASK_COMPLETED = 'task_completed';
    const TYPE_PAYMENT_RELEASED = 'payment_released';
    const TYPE_DISPUTE_OPENED = 'dispute_opened';
    const TYPE_DISPUTE_RESOLVED = 'dispute_resolved';
    const TYPE_KYC_APPROVED = 'kyc_approved';
    const TYPE_KYC_REJECTED = 'kyc_rejected';
    const TYPE_PANIC_ALERT = 'panic_alert';
    const TYPE_SUSPENSION = 'suspension';
    const TYPE_ANNOUNCEMENT = 'announcement';
    const TYPE_ERRAND_OFFER = 'errand_offer';

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function isRead(): bool
    {
        return !is_null($this->read_at);
    }
}
