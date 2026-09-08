#!/bin/sh
set -e

cd /var/www/html

if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:" ]; then
  echo "APP_KEY is missing. Set APP_KEY in .env before starting the container."
  exit 1
fi

mkdir -p storage/framework/{cache,sessions,views} storage/logs storage/app/public bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
chmod -R ug+rwx storage bootstrap/cache

# Public disk URLs (/storage/...) — safe if link already exists
if [ ! -L public/storage ] && [ ! -e public/storage ]; then
  php artisan storage:link --no-interaction 2>/dev/null || ln -sfn /var/www/html/storage/app/public /var/www/html/public/storage
elif [ -d public/storage ] && [ ! -L public/storage ]; then
  echo "WARNING: public/storage is a directory (not a symlink). Prefer S3 (FILESYSTEM_DISK=s3) or remove the directory and recreate the link."
fi

if [ "${WAIT_FOR_DB:-true}" = "true" ]; then
  echo "Waiting for database..."
  i=0
  until php artisan db:show >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge 30 ]; then
      echo "Database not reachable after 60 seconds."
      exit 1
    fi
    sleep 2
  done
  echo "Database is ready."
fi

if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
  php artisan migrate --force --no-interaction
fi

if [ "${RUN_SEEDERS:-false}" = "true" ]; then
  php artisan db:seed --force --no-interaction
fi

if [ "${CACHE_CONFIG:-true}" = "true" ] && [ "${APP_ENV:-local}" = "production" ]; then
  php artisan config:cache
  php artisan route:cache
  php artisan view:cache
fi

exec "$@"
