#!/bin/sh
# Render free-tier start: bind nginx to $PORT, run queue + scheduler alongside API.
# Invoked as Docker CMD (after entrypoint.sh finishes migrate/cache).
set -e
cd /var/www/html

PORT="${PORT:-80}"

# Render injects PORT; stock nginx listens on 80
if [ -f /etc/nginx/sites-available/default ]; then
  sed -i "s/listen [0-9]*;/listen ${PORT};/" /etc/nginx/sites-available/default
fi

# Free plan has no Background Worker — run in-process (same free web instance)
if [ "${RENDER_RUN_QUEUE:-true}" = "true" ]; then
  echo "Starting queue worker (RENDER_RUN_QUEUE=true)..."
  php artisan queue:work redis --sleep=3 --tries=3 --max-time=3600 &
fi

if [ "${RENDER_RUN_SCHEDULER:-true}" = "true" ]; then
  echo "Starting scheduler loop (RENDER_RUN_SCHEDULER=true)..."
  (
    while true; do
      php artisan schedule:run --verbose --no-interaction || true
      sleep 60
    done
  ) &
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
