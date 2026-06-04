<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

$app = require __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$pdo = Illuminate\Support\Facades\DB::connection()->getPdo();
$schemas = $pdo->query("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'public'")->fetchColumn();

if ($schemas) {
    echo "public_schema_exists=yes\n";
    exit(0);
}

try {
    $pdo->exec('CREATE SCHEMA public');
    echo "public_schema_created=yes\n";
} catch (Throwable $e) {
    echo "public_schema_created=no\n";
    echo 'error=' . $e->getMessage() . "\n";
    exit(1);
}
