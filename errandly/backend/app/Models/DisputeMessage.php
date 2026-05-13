<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DisputeMessage extends Model
{
    use HasFactory;

    protected $fillable = [
        'dispute_id',
        'sender_id',
        'content',
        'is_admin',
    ];

    protected $casts = [
        'is_admin' => 'boolean',
    ];

    public function dispute()
    {
        return $this->belongsTo(Dispute::class);
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
