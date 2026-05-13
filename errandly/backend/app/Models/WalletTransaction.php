<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WalletTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'wallet_id',
        'type',
        'direction',
        'amount',
        'description',
        'reference_id',
        'reference_type',
        'balance_after',
        'status',
        'metadata',
    ];

    protected $casts = [
        'amount' => 'integer',
        'balance_after' => 'integer',
        'metadata' => 'array',
    ];

    const TYPE_FUNDING = 'funding';
    const TYPE_PAYMENT = 'errand_payment';
    const TYPE_EARNINGS = 'earnings';
    const TYPE_REFUND = 'refund';
    const TYPE_WITHDRAWAL = 'withdrawal';
    const TYPE_COMMISSION = 'commission';
    const TYPE_BONUS = 'bonus';
    const TYPE_TIP = 'tip';
    const TYPE_FREEZE = 'freeze';

    const DIRECTION_CREDIT = 'credit';
    const DIRECTION_DEBIT = 'debit';

    public function wallet()
    {
        return $this->belongsTo(Wallet::class);
    }
}
