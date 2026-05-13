<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class Errand extends Model
{
    use HasFactory, SoftDeletes, LogsActivity;

    protected $fillable = [
        'customer_id',
        'runner_id',
        'title',
        'description',
        'category',
        'status',
        'urgency',
        'pickup_address',
        'pickup_latitude',
        'pickup_longitude',
        'pickup_city',
        'destination_address',
        'destination_latitude',
        'destination_longitude',
        'destination_city',
        'recipient_name',
        'recipient_phone',
        'item_details',
        'special_instructions',
        'budget',
        'platform_fee',
        'runner_earnings',
        'scheduled_at',
        'accepted_at',
        'started_at',
        'completed_at',
        'cancelled_at',
        'failed_at',
        'cancellation_reason',
        'cancellation_by',
        'failure_reason',
        'pickup_otp',
        'pickup_otp_verified_at',
        'delivery_otp',
        'delivery_otp_verified_at',
        'is_recurring',
        'recurring_schedule',
        'panic_triggered_at',
        'panic_triggered_by',
        'payment_status',
        'escrow_id',
        'attachments',
        'estimated_duration_minutes',
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
        'accepted_at' => 'datetime',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'failed_at' => 'datetime',
        'pickup_otp_verified_at' => 'datetime',
        'delivery_otp_verified_at' => 'datetime',
        'panic_triggered_at' => 'datetime',
        'budget' => 'integer',
        'platform_fee' => 'integer',
        'runner_earnings' => 'integer',
        'pickup_latitude' => 'float',
        'pickup_longitude' => 'float',
        'destination_latitude' => 'float',
        'destination_longitude' => 'float',
        'is_recurring' => 'boolean',
        'recurring_schedule' => 'array',
        'attachments' => 'array',
    ];

    // Status constants - full lifecycle
    const STATUS_DRAFT = 'draft';
    const STATUS_POSTED = 'posted';
    const STATUS_PENDING_ASSIGNMENT = 'pending_assignment';
    const STATUS_ACCEPTED = 'accepted';
    const STATUS_RUNNER_EN_ROUTE = 'runner_en_route';
    const STATUS_ITEM_PICKED = 'item_picked';
    const STATUS_IN_PROGRESS = 'in_progress';
    const STATUS_AWAITING_CONFIRMATION = 'awaiting_confirmation';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_FAILED = 'failed';
    const STATUS_DISPUTED = 'disputed';
    const STATUS_REFUNDED = 'refunded';

    // Category constants
    const CATEGORY_PACKAGE_PICKUP = 'package_pickup';
    const CATEGORY_ITEM_DELIVERY = 'item_delivery';
    const CATEGORY_GROCERY = 'grocery_purchase';
    const CATEGORY_QUEUE_STANDING = 'queue_standing';
    const CATEGORY_DOCUMENT_SUBMISSION = 'document_submission';
    const CATEGORY_DOCUMENT_COLLECTION = 'document_collection';
    const CATEGORY_SHOPPING = 'shopping_assistance';
    const CATEGORY_PRESCRIPTION = 'prescription_pickup';
    const CATEGORY_PERSONAL = 'personal_assistance';
    const CATEGORY_CUSTOM = 'custom_errand';

    // Urgency constants
    const URGENCY_STANDARD = 'standard';
    const URGENCY_URGENT = 'urgent';
    const URGENCY_SCHEDULED = 'scheduled';

    // Payment status
    const PAYMENT_PENDING = 'pending_funding';
    const PAYMENT_FUNDED = 'funded';
    const PAYMENT_IN_ESCROW = 'in_escrow';
    const PAYMENT_RELEASED = 'released';
    const PAYMENT_REFUNDED = 'refunded';
    const PAYMENT_FROZEN = 'frozen';

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function runner()
    {
        return $this->belongsTo(User::class, 'runner_id');
    }

    public function escrow()
    {
        return $this->hasOne(EscrowTransaction::class);
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function trackingLogs()
    {
        return $this->hasMany(TrackingLog::class);
    }

    public function proofSubmissions()
    {
        return $this->hasMany(ProofSubmission::class);
    }

    public function dispute()
    {
        return $this->hasOne(Dispute::class);
    }

    public function ratings()
    {
        return $this->hasMany(Rating::class);
    }

    public function panicEvents()
    {
        return $this->hasMany(PanicEvent::class);
    }

    public function statusHistory()
    {
        return $this->hasMany(ErrandStatusHistory::class)->orderBy('created_at', 'asc');
    }

    public function isActive(): bool
    {
        return in_array($this->status, [
            self::STATUS_ACCEPTED,
            self::STATUS_RUNNER_EN_ROUTE,
            self::STATUS_ITEM_PICKED,
            self::STATUS_IN_PROGRESS,
            self::STATUS_AWAITING_CONFIRMATION,
        ]);
    }

    public function canBeCancelledByCustomer(): bool
    {
        return in_array($this->status, [
            self::STATUS_POSTED,
            self::STATUS_PENDING_ASSIGNMENT,
            self::STATUS_ACCEPTED,
            self::STATUS_RUNNER_EN_ROUTE,
        ]);
    }

    public function canBeCancelledByRunner(): bool
    {
        return in_array($this->status, [
            self::STATUS_ACCEPTED,
            self::STATUS_RUNNER_EN_ROUTE,
        ]);
    }

    public function totalAmount(): int
    {
        return $this->budget + $this->platform_fee;
    }

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['status', 'runner_id', 'payment_status'])
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs();
    }
}
