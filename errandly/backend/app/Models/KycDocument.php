<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class KycDocument extends Model
{
    use HasFactory, LogsActivity;

    protected $fillable = [
        'user_id',
        'reviewed_by',
        'status',
        'type',
        'id_type',
        'id_number',
        'id_document_url',
        'selfie_url',
        'live_photo_url',
        'address_proof_url',
        'utility_bill_url',
        'nin_number',
        'bvn_number',
        'submitted_at',
        'reviewed_at',
        'rejection_reason',
        'resubmission_reason',
        'notes',
        'face_match_score',
        'liveness_score',
        'document_confidence',
    ];

    protected $casts = [
        'submitted_at' => 'datetime',
        'reviewed_at' => 'datetime',
        'face_match_score' => 'float',
        'liveness_score' => 'float',
        'document_confidence' => 'float',
    ];

    // Status
    const STATUS_PENDING = 'pending';
    const STATUS_SUBMITTED = 'submitted';
    const STATUS_UNDER_REVIEW = 'under_review';
    const STATUS_APPROVED = 'approved';
    const STATUS_REJECTED = 'rejected';
    const STATUS_RESUBMISSION_REQUIRED = 'resubmission_required';

    // ID Types
    const ID_NATIONAL = 'national_id';
    const ID_DRIVERS_LICENSE = 'drivers_license';
    const ID_PASSPORT = 'passport';
    const ID_VOTERS_CARD = 'voters_card';

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function isApproved(): bool
    {
        return $this->status === self::STATUS_APPROVED;
    }

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['status', 'reviewed_by', 'rejection_reason'])
            ->logOnlyDirty();
    }
}
