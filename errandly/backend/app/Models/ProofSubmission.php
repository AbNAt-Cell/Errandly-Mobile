<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProofSubmission extends Model
{
    use HasFactory;

    protected $fillable = [
        'errand_id',
        'runner_id',
        'type',
        'file_url',
        'notes',
        'submitted_at',
        'verified_at',
    ];

    protected $casts = [
        'submitted_at' => 'datetime',
        'verified_at' => 'datetime',
    ];

    const TYPE_PHOTO = 'photo';
    const TYPE_RECEIPT = 'receipt';
    const TYPE_SIGNATURE = 'signature';
    const TYPE_NOTE = 'note';

    public function errand()
    {
        return $this->belongsTo(Errand::class);
    }

    public function runner()
    {
        return $this->belongsTo(User::class, 'runner_id');
    }
}
