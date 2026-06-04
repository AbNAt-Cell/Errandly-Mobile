<?php

namespace App\Services\Fcm;

enum FcmSendResult: string
{
    case Sent = 'sent';
    case Skipped = 'skipped';
    case TokenInvalid = 'token_invalid';
    case Failed = 'failed';
}
