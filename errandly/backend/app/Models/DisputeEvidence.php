<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DisputeEvidence extends Model
{
    use HasFactory;

    protected $fillable = [
        'dispute_id',
        'submitted_by',
        'type',
        'url',
        'description',
    ];

    const TYPE_PHOTO = 'photo';
    const TYPE_VIDEO = 'video';
    const TYPE_DOCUMENT = 'document';
    const TYPE_TEXT = 'text';

    public function dispute()
    {
        return $this->belongsTo(Dispute::class);
    }

    public function submittedBy()
    {
        return $this->belongsTo(User::class, 'submitted_by');
    }
}
