<?php

namespace App\Support\Schema;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use ReflectionClass;

class ModelTableVerifier
{
    /** @return class-string<Model>[] */
    public static function modelClasses(): array
    {
        $models = [];

        foreach (File::allFiles(app_path('Models')) as $file) {
            $class = 'App\\Models\\' . $file->getFilenameWithoutExtension();

            if (! class_exists($class)) {
                continue;
            }

            $reflection = new ReflectionClass($class);

            if ($reflection->isAbstract() || ! $reflection->isSubclassOf(Model::class)) {
                continue;
            }

            $models[] = $class;
        }

        sort($models);

        return $models;
    }

    /** @return list<string> */
    public static function migrationTableNames(): array
    {
        $tables = [];

        foreach (File::glob(database_path('migrations/*.php')) as $path) {
            $contents = File::get($path);

            preg_match_all("/Schema::create\(\s*['\"]([^'\"]+)['\"]/", $contents, $creates);
            preg_match_all("/Schema::rename\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]/", $contents, $renames);

            foreach ($creates[1] ?? [] as $table) {
                $tables[] = $table;
            }

            foreach ($renames[2] ?? [] as $table) {
                $tables[] = $table;
            }
        }

        return array_values(array_unique($tables));
    }

    /**
     * @return array{
     *     model: class-string<Model>,
     *     table: string,
     *     missing_in_migrations: bool,
     *     missing_in_database: bool|null
     * }[]
     */
    public static function verify(bool $checkDatabase = false): array
    {
        $migrationTables = self::migrationTableNames();
        $results = [];

        foreach (self::modelClasses() as $modelClass) {
            /** @var Model $model */
            $model = new $modelClass;
            $table = $model->getTable();

            $results[] = [
                'model' => $modelClass,
                'table' => $table,
                'missing_in_migrations' => ! in_array($table, $migrationTables, true),
                'missing_in_database' => $checkDatabase
                    ? ! Schema::hasTable($table)
                    : null,
            ];
        }

        return $results;
    }

    /** @return list<string> */
    public static function failures(bool $checkDatabase = false): array
    {
        $messages = [];

        foreach (self::verify($checkDatabase) as $result) {
            $shortName = class_basename($result['model']);

            if ($result['missing_in_migrations']) {
                $messages[] = "{$shortName} expects table [{$result['table']}] but no migration creates it.";
            }

            if ($result['missing_in_database'] === true) {
                $messages[] = "{$shortName} expects table [{$result['table']}] but it is missing in the database.";
            }
        }

        return $messages;
    }

    public static function passes(bool $checkDatabase = false): bool
    {
        return self::failures($checkDatabase) === [];
    }
}
