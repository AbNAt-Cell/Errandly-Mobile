<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Activitylog\LogOptions;

class Wallet extends Model
{
    use HasFactory, LogsActivity;

    protected $fillable = [
        'user_id',
        'balance',
        'escrow_balance',
        'pending_withdrawal',
        'currency',
        'is_frozen',
        'frozen_reason',
        'frozen_at',
        'total_funded',
        'total_withdrawn',
        'total_earned',
    ];

    protected $casts = [
        'balance' => 'integer',
        'escrow_balance' => 'integer',
        'pending_withdrawal' => 'integer',
        'total_funded' => 'integer',
        'total_withdrawn' => 'integer',
        'total_earned' => 'integer',
        'is_frozen' => 'boolean',
        'frozen_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function transactions()
    {
        return $this->hasMany(WalletTransaction::class)->orderBy('created_at', 'desc');
    }

    public function getAvailableBalance(): int
    {
        return $this->balance - $this->pending_withdrawal;
    }

    public function hasSufficientFunds(int $amount): bool
    {
        return !$this->is_frozen && $this->getAvailableBalance() >= $amount;
    }

    // Credit the wallet (atomic)
    public function credit(int $amount, string $type, string $description, ?int $referenceId = null, string $referenceType = null): WalletTransaction
    {
        $this->increment('balance', $amount);
        return $this->transactions()->create([
            'type' => $type,
            'direction' => 'credit',
            'amount' => $amount,
            'description' => $description,
            'reference_id' => $referenceId,
            'reference_type' => $referenceType,
            'balance_after' => $this->fresh()->balance,
        ]);
    }

    // Debit the wallet (atomic)
    public function debit(int $amount, string $type, string $description, ?int $referenceId = null, string $referenceType = null): WalletTransaction
    {
        $this->decrement('balance', $amount);
        return $this->transactions()->create([
            'type' => $type,
            'direction' => 'debit',
            'amount' => $amount,
            'description' => $description,
            'reference_id' => $referenceId,
            'reference_type' => $referenceType,
            'balance_after' => $this->fresh()->balance,
        ]);
    }

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['balance', 'is_frozen'])
            ->logOnlyDirty();
    }
}
