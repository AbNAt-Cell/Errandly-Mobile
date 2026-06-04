<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiDocumentChunk extends Model
{
    protected $fillable = [
        'corpus',
        'source_path',
        'chunk_index',
        'content',
        'content_hash',
        'metadata',
        'embedding',
    ];

    protected $casts = [
        'metadata' => 'array',
        'embedding' => 'array',
    ];
}
