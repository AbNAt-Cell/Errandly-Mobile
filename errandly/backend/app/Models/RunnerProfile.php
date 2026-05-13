<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RunnerProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'nin',
        'bank_name',
        'bank_account_number',
        'bank_account_name',
        'bank_code',
        'next_of_kin_name',
        'next_of_kin_phone',
        'next_of_kin_relationship',
        'guarantor_name',
        'guarantor_phone',
        'guarantor_address',
        'transport_type',
        'service_radius_km',
        'service_city',
        'service_state',
        'skills',
        'available_days',
        'available_hours_start',
        'available_hours_end',
        'is_available',
        'is_verified',
        'verification_status',
        'verified_at',
        'trust_score',
        'completion_rate',
        'total_errands',
        'cancelled_errands',
        'average_rating',
        'total_earnings',
        'current_latitude',
        'current_longitude',
        'location_updated_at',
        'background_check_status',
        'is_online',
    ];

    protected $casts = [
        'skills' => 'array',
        'available_days' => 'array',
        'is_available' => 'boolean',
        'is_verified' => 'boolean',
        'is_online' => 'boolean',
        'trust_score' => 'float',
        'completion_rate' => 'float',
        'average_rating' => 'float',
        'total_earnings' => 'integer',
        'current_latitude' => 'float',
        'current_longitude' => 'float',
        'location_updated_at' => 'datetime',
        'verified_at' => 'datetime',
    ];

    // Transport types
    const TRANSPORT_FOOT = 'foot';
    const TRANSPORT_BICYCLE = 'bicycle';
    const TRANSPORT_MOTORCYCLE = 'motorcycle';
    const TRANSPORT_CAR = 'car';

    // Verification status
    const VERIFICATION_PENDING = 'pending';
    const VERIFICATION_SUBMITTED = 'submitted';
    const VERIFICATION_APPROVED = 'approved';
    const VERIFICATION_REJECTED = 'rejected';

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function isVerified(): bool
    {
        return $this->verification_status === self::VERIFICATION_APPROVED;
    }

    public function updateTrustScore(): void
    {
        $score = 100;

        // Deduct for cancellations
        if ($this->total_errands > 0) {
            $cancellationRate = $this->cancelled_errands / $this->total_errands;
            $score -= ($cancellationRate * 30);
        }

        // Factor in ratings (0-5 scale, weighted 40 points)
        if ($this->average_rating > 0) {
            $score -= ((5 - $this->average_rating) / 5) * 40;
        }

        // Factor in completion rate
        $score *= ($this->completion_rate / 100);

        $this->trust_score = max(0, min(100, round($score, 2)));
        $this->save();
    }
}
