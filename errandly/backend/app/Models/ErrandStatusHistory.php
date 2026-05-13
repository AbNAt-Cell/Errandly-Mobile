<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ErrandStatusHistory extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'errand_id',
        'from_status',
        'to_status',
        'changed_by',
        'reason',
        'metadata',
        'created_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'created_at' => 'datetime',
    ];

    public function errand()
    {
        return $this->belongsTo(Errand::class);
    }

    public function changedBy()
    {
        return $this->belongsTo(User::class, 'changed_by');
    }
}
