<?php

namespace App\Http\Controllers\Concerns;

use App\Models\Errand;
use App\Models\User;

trait AuthorizesErrandAccess
{
    protected function authorizeErrandView(User $user, Errand $errand): void
    {
        if ($user->hasAnyRole(['admin', 'super_admin', 'verification_officer'])) {
            return;
        }

        if ($user->hasRole('customer') && (int) $errand->customer_id === (int) $user->id) {
            return;
        }

        if ($user->hasRole('runner') && (int) $errand->runner_id === (int) $user->id) {
            return;
        }

        abort(404);
    }

    protected function authorizeErrandCustomer(User $user, Errand $errand): void
    {
        if ((int) $errand->customer_id !== (int) $user->id) {
            abort(404);
        }
    }

    protected function authorizeErrandRunner(User $user, Errand $errand): void
    {
        if ((int) $errand->runner_id !== (int) $user->id) {
            abort(404);
        }
    }

    protected function authorizeErrandParticipant(User $user, Errand $errand): void
    {
        if (
            (int) $errand->customer_id === (int) $user->id
            || (int) $errand->runner_id === (int) $user->id
        ) {
            return;
        }

        abort(404);
    }
}
