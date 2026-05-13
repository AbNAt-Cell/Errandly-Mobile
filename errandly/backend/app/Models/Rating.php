<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rating extends Model
{
    use HasFactory;

    protected $fillable = [
        'errand_id',
        'rater_id',
        'rated_id',
        'role',
        'overall_rating',
        'punctuality',
        'professionalism',
        'communication',
        'accuracy',
        'safety',
        'trustworthiness',
        'clarity',
        'politeness',
        'payment_reliability',
        'honesty',
        'comment',
        'is_anonymous',
    ];

    protected $casts = [
        'overall_rating' => 'float',
        'punctuality' => 'float',
        'professionalism' => 'float',
        'communication' => 'float',
        'accuracy' => 'float',
        'safety' => 'float',
        'trustworthiness' => 'float',
        'clarity' => 'float',
        'politeness' => 'float',
        'payment_reliability' => 'float',
        'honesty' => 'float',
        'is_anonymous' => 'boolean',
    ];

    const ROLE_CUSTOMER_TO_RUNNER = 'customer_rates_runner';
    const ROLE_RUNNER_TO_CUSTOMER = 'runner_rates_customer';

    public function errand()
    {
        return $this->belongsTo(Errand::class);
    }

    public function rater()
    {
        return $this->belongsTo(User::class, 'rater_id');
    }

    public function rated()
    {
        return $this->belongsTo(User::class, 'rated_id');
    }
}
