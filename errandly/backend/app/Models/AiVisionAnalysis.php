<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiVisionAnalysis extends Model
{
    protected $fillable = [
        'subject_type',
        'subject_id',
        'model',
        'result',
        'flags',
    ];

    protected $casts = [
        'result' => 'array',
        'flags' => 'array',
    ];
}
