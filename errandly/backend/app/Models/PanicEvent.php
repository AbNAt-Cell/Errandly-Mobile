<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PanicEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'errand_id',
        'triggered_by',
        'latitude',
        'longitude',
        'status',
        'notes',
        'admin_id',
        'resolved_at',
        'resolution_notes',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'resolved_at' => 'datetime',
    ];

    const STATUS_ACTIVE = 'active';
    const STATUS_RESPONDED = 'responded';
    const STATUS_RESOLVED = 'resolved';

    public function errand()
    {
        return $this->belongsTo(Errand::class);
    }

    public function triggeredBy()
    {
        return $this->belongsTo(User::class, 'triggered_by');
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
