<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiFraudSignal extends Model
{
    protected $fillable = [
        'signal_type',
        'subject_type',
        'subject_id',
        'severity',
        'status',
        'evidence',
        'summary',
    ];

    protected $casts = [
        'evidence' => 'array',
    ];

    public const STATUS_OPEN = 'open';
    public const STATUS_REVIEWED = 'reviewed';
    public const STATUS_DISMISSED = 'dismissed';
}
