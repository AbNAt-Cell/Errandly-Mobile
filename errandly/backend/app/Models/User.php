<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Authenticatable implements HasMedia
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles, InteractsWithMedia, LogsActivity, SoftDeletes;

    protected $fillable = [
        'first_name',
        'last_name',
        'middle_name',
        'email',
        'phone',
        'password',
        'phone_verified_at',
        'email_verified_at',
        'profile_image',
        'date_of_birth',
        'gender',
        'address',
        'city',
        'state',
        'country',
        'latitude',
        'longitude',
        'emergency_contact_name',
        'emergency_contact_phone',
        'referral_code',
        'referred_by',
        'status',
        'is_online',
        'last_seen_at',
        'device_token',
        'device_type',
        'kyc_status',
        'suspension_reason',
        'suspended_at',
        'suspended_until',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'phone_verified_at' => 'datetime',
        'suspended_at' => 'datetime',
        'suspended_until' => 'datetime',
        'last_seen_at' => 'datetime',
        'is_online' => 'boolean',
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    // Status constants
    const STATUS_ACTIVE = 'active';
    const STATUS_SUSPENDED = 'suspended';
    const STATUS_BLACKLISTED = 'blacklisted';
    const STATUS_PENDING = 'pending';

    // KYC status constants
    const KYC_PENDING = 'pending';
    const KYC_SUBMITTED = 'submitted';
    const KYC_APPROVED = 'approved';
    const KYC_REJECTED = 'rejected';

    public function getFullNameAttribute(): string
    {
        return "{$this->first_name} {$this->last_name}";
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }

    public function isSuspended(): bool
    {
        return $this->status === self::STATUS_SUSPENDED;
    }

    public function isKycApproved(): bool
    {
        return $this->kyc_status === self::KYC_APPROVED;
    }

    // Relationships
    public function wallet()
    {
        return $this->hasOne(Wallet::class);
    }

    public function kyc()
    {
        return $this->hasOne(KycDocument::class);
    }

    public function runnerProfile()
    {
        return $this->hasOne(RunnerProfile::class);
    }

    public function customerErrands()
    {
        return $this->hasMany(Errand::class, 'customer_id');
    }

    public function runnerErrands()
    {
        return $this->hasMany(Errand::class, 'runner_id');
    }

    public function ratingsGiven()
    {
        return $this->hasMany(Rating::class, 'rater_id');
    }

    public function ratingsReceived()
    {
        return $this->hasMany(Rating::class, 'rated_id');
    }

    public function disputes()
    {
        return $this->hasMany(Dispute::class, 'raised_by');
    }

    public function notifications()
    {
        return $this->hasMany(AppNotification::class);
    }

    public function savedAddresses()
    {
        return $this->hasMany(SavedAddress::class);
    }

    public function paymentTransactions()
    {
        return $this->hasMany(PaymentTransaction::class);
    }

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['status', 'kyc_status', 'is_online'])
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs();
    }

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('profile_image')->singleFile();
        $this->addMediaCollection('kyc_documents');
    }
}
