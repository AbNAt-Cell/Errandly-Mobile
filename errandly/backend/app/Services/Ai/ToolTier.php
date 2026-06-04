<?php

namespace App\Services\Ai;

enum ToolTier: string
{
    case Read = 'read';
    case Analyze = 'analyze';
    case Propose = 'propose';
    case ConfirmWrite = 'confirm_write';
}
