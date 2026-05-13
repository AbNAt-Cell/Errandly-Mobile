<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dispute extends Model
{
    use HasFactory;

    protected $fillable = [
        'errand_id',
        'raised_by',
        'assigned_to',
        'type',
        'status',
        'description',
        'resolution',
        'resolution_type',
        'resolved_at',
        'refund_amount',
        'penalty_applied',
        'evidence',
        'closed_at',
        'closing_notes',
    ];

    protected $casts = [
        'resolved_at' => 'datetime',
        'closed_at' => 'datetime',
        'evidence' => 'array',
        'refund_amount' => 'integer',
        'penalty_applied' => 'boolean',
    ];

    const STATUS_OPEN = 'open';
    const STATUS_UNDER_REVIEW = 'under_review';
    const STATUS_AWAITING_EVIDENCE = 'awaiting_evidence';
    const STATUS_RESOLVED = 'resolved';
    const STATUS_CLOSED = 'closed';

    const TYPE_ITEM_NOT_DELIVERED = 'item_not_delivered';
    const TYPE_ITEM_DAMAGED = 'item_damaged';
    const TYPE_WRONG_EXECUTION = 'wrong_task_execution';
    const TYPE_HARASSMENT = 'harassment';
    const TYPE_FRAUDULENT_COMPLETION = 'fraudulent_completion';
    const TYPE_MISSING_PAYMENT = 'missing_payment';
    const TYPE_OTHER = 'other';

    const RESOLUTION_REFUND = 'refund';
    const RESOLUTION_RELEASE = 'release';
    const RESOLUTION_PARTIAL_REFUND = 'partial_refund';
    const RESOLUTION_NO_ACTION = 'no_action';

    public function errand()
    {
        return $this->belongsTo(Errand::class);
    }

    public function raisedBy()
    {
        return $this->belongsTo(User::class, 'raised_by');
    }

    public function assignedTo()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    public function evidenceFiles()
    {
        return $this->hasMany(DisputeEvidence::class);
    }

    public function messages()
    {
        return $this->hasMany(DisputeMessage::class);
    }
}
