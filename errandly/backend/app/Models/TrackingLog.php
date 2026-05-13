<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TrackingLog extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'errand_id',
        'runner_id',
        'latitude',
        'longitude',
        'speed',
        'heading',
        'accuracy',
        'logged_at',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'speed' => 'float',
        'heading' => 'float',
        'accuracy' => 'float',
        'logged_at' => 'datetime',
    ];

    public function errand()
    {
        return $this->belongsTo(Errand::class);
    }

    public function runner()
    {
        return $this->belongsTo(User::class, 'runner_id');
    }
}
