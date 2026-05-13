<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'errand_id',
        'sender_id',
        'type',
        'content',
        'media_url',
        'media_type',
        'duration_seconds',
        'read_at',
        'is_system',
    ];

    protected $casts = [
        'read_at' => 'datetime',
        'is_system' => 'boolean',
    ];

    const TYPE_TEXT = 'text';
    const TYPE_IMAGE = 'image';
    const TYPE_VOICE = 'voice';
    const TYPE_SYSTEM = 'system';
    const TYPE_LOCATION = 'location';

    public function errand()
    {
        return $this->belongsTo(Errand::class);
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function isRead(): bool
    {
        return !is_null($this->read_at);
    }
}
