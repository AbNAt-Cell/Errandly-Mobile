<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserNotificationPreference extends Model
{
    protected $fillable = [
        'user_id',
        'push_enabled',
        'errand_updates',
        'payments',
        'account',
        'marketing',
        'alerts',
    ];

    protected $casts = [
        'push_enabled' => 'boolean',
        'errand_updates' => 'boolean',
        'payments' => 'boolean',
        'account' => 'boolean',
        'marketing' => 'boolean',
        'alerts' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
