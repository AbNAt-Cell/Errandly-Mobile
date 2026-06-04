<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

$app = require __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$rawUrl = env('DATABASE_URL');
$parsed = is_string($rawUrl) ? parse_url($rawUrl) : false;

echo 'env_url_set=' . (empty($rawUrl) ? 'no' : 'yes') . PHP_EOL;
echo 'env_url_host=' . ($parsed['host'] ?? 'null') . PHP_EOL;
echo 'env_url_db=' . (isset($parsed['path']) ? ltrim($parsed['path'], '/') : 'null') . PHP_EOL;
if (!empty($parsed['query'])) {
    parse_str($parsed['query'], $query);
    echo 'env_url_schema=' . ($query['schema'] ?? 'unset') . PHP_EOL;
}

$config = config('database.connections.pgsql');

echo 'url_set=' . (empty($config['url']) ? 'no' : 'yes') . PHP_EOL;
echo 'host=' . ($config['host'] ?? 'null') . PHP_EOL;
echo 'database=' . ($config['database'] ?? 'null') . PHP_EOL;
echo 'prisma_host=' . (str_contains((string) ($config['host'] ?? ''), 'prisma.io') ? 'yes' : 'no') . PHP_EOL;

$live = Illuminate\Support\Facades\DB::connection()->getConfig();
echo 'live_host=' . ($live['host'] ?? 'null') . PHP_EOL;
echo 'live_database=' . ($live['database'] ?? 'null') . PHP_EOL;
echo 'live_prisma=' . (str_contains((string) ($live['host'] ?? ''), 'prisma.io') ? 'yes' : 'no') . PHP_EOL;
echo 'live_search_path=' . json_encode($live['search_path'] ?? $live['schema'] ?? null) . PHP_EOL;

try {
    $pdo = Illuminate\Support\Facades\DB::connection()->getPdo();
    echo 'pdo_ok=yes' . PHP_EOL;
    $sp = $pdo->query('SHOW search_path')->fetchColumn();
    echo 'session_search_path=' . $sp . PHP_EOL;
    $schemas = $pdo->query("SELECT schema_name FROM information_schema.schemata ORDER BY schema_name")->fetchAll(PDO::FETCH_COLUMN);
    echo 'schemas=' . implode(',', $schemas) . PHP_EOL;

} catch (Throwable $e) {
    echo 'pdo_ok=no' . PHP_EOL;
    echo 'error=' . $e->getMessage() . PHP_EOL;
}
