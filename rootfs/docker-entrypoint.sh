#!/bin/bash
set -e

verbose_log() {
    [ "${VERBOSE}" = "true" ] && echo "$@" || true
}

verbose_log "Starting PressHost..."

if [ -n "$TZ" ] && [ -f "/usr/share/zoneinfo/$TZ" ]; then
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
fi

verbose_log "Setting up runtime directories..."
mkdir -p /run/nginx /run/php "${CACHE_PATH}/nginx/fastcgi" "${CACHE_PATH}"
fast-chown /run/php /run/nginx "${CACHE_PATH}/nginx"

if [ -f "/etc/logrotate.d/presshost.tpl" ]; then
    envsubst '$LOG_MAX_SIZE $LOG_MAX_AGE $APP_USER $APP_GROUP $LOGS_PATH' < /etc/logrotate.d/presshost.tpl > /etc/logrotate.d/presshost
    verbose_log "Log rotation configured"
fi

if [ "${ALLOW_RUNTIME_PHP_ENVVARS}" = "true" ]; then
    export PHP_CLEAR_ENV="no"
else
    export PHP_CLEAR_ENV="yes"
fi

TEMPLATE_VARS='$APP_USER $APP_GROUP $APP_PATH $UPLOADS_PATH $CACHE_PATH $LOGS_PATH $PHP_PM $PHP_PM_MAX_CHILDREN $PHP_PM_START_SERVERS $PHP_PM_MIN_SPARE_SERVERS $PHP_PM_MAX_SPARE_SERVERS $PHP_PM_MAX_REQUESTS $PHP_MAX_EXECUTION_TIME $PHP_MAX_INPUT_TIME $PHP_MAX_INPUT_VARS $PHP_MEMORY_LIMIT $PHP_POST_MAX_SIZE $PHP_UPLOAD_MAX_FILESIZE $PHP_OPCACHE_ENABLE $PHP_OPCACHE_MEMORY $PHP_OPCACHE_INTERNED_STRINGS $PHP_OPCACHE_MAX_FILES $PHP_OPCACHE_REVALIDATE_FREQ $PHP_OPCACHE_VALIDATE_TIMESTAMPS $PHP_SESSION_COOKIE_HTTPONLY $PHP_SESSION_COOKIE_SECURE $PHP_SESSION_USE_STRICT_MODE $PHP_APC_ENABLED $PHP_APC_SHM_SIZE $PHP_APC_TTL $PHP_APC_ENABLE_CLI $PHP_REALPATH_CACHE_SIZE $PHP_REALPATH_CACHE_TTL $TZ $PHP_CLEAR_ENV $NGINX_CLIENT_MAX_BODY_SIZE $NGINX_CACHE_MAX_SIZE $NGINX_CACHE_INACTIVE $NGINX_CLIENT_BODY_BUFFER_SIZE $NGINX_CLIENT_HEADER_BUFFER_SIZE $NGINX_LARGE_CLIENT_HEADER_BUFFERS $NGINX_OUTPUT_BUFFERS $NGINX_FASTCGI_BUFFER_SIZE $NGINX_FASTCGI_BUFFERS $NGINX_FASTCGI_BUSY_BUFFERS_SIZE $SSL_CERT_PATH $SSL_PRIVATE_PATH $NGINX_SSL_STAPLING $NGINX_SSL_STAPLING_VERIFY'

if [ -f "/etc/php/8.4/fpm/pool.d/www.conf.tpl" ]; then
    envsubst "$TEMPLATE_VARS" < /etc/php/8.4/fpm/pool.d/www.conf.tpl > /etc/php/8.4/fpm/pool.d/www.conf
    verbose_log "PHP-FPM pool configuration generated"
fi

if [ -f "/etc/php/8.4/fpm/conf.d/99-presshost.ini.tpl" ]; then
    envsubst "$TEMPLATE_VARS" < /etc/php/8.4/fpm/conf.d/99-presshost.ini.tpl > /etc/php/8.4/fpm/conf.d/99-presshost.ini
    cp /etc/php/8.4/fpm/conf.d/99-presshost.ini /etc/php/8.4/cli/conf.d/99-presshost.ini
    verbose_log "PHP ini configuration generated"
fi

if [ -f "/etc/nginx/nginx.conf.tpl" ]; then
    envsubst "$TEMPLATE_VARS" < /etc/nginx/nginx.conf.tpl > /etc/nginx/nginx.conf
    verbose_log "NGINX configuration generated"
fi

if [ "${NGINX_CACHE}" = "false" ]; then
    echo "# Cache - Disabled" > /etc/nginx/cache_php_fastcgi.conf
    echo "# Cache - Disabled" > /etc/nginx/cache_server.conf
    verbose_log "NGINX FastCGI cache disabled"
else
    verbose_log "NGINX FastCGI cache enabled"
fi

if [ -f "/etc/nginx/sites-enabled/presshost.conf.tpl" ]; then
    envsubst "$TEMPLATE_VARS" < /etc/nginx/sites-enabled/presshost.conf.tpl > /etc/nginx/sites-enabled/presshost.conf
    verbose_log "NGINX site configuration generated"
fi

if [ -f "/etc/supervisor/supervisord.conf.tpl" ]; then
    envsubst '$LOGS_PATH' < /etc/supervisor/supervisord.conf.tpl > /etc/supervisor/supervisord.conf
    verbose_log "Supervisor configuration generated"
fi

for tpl in /etc/supervisor/conf.d/*.tpl; do
    if [ -f "$tpl" ]; then
        conf="${tpl%.tpl}"
        envsubst '$LOGS_PATH' < "$tpl" > "$conf"
    fi
done

if [ -d "${APP_PATH}/wp-content" ]; then
    if [ -d "${APP_PATH}/wp-content/cache" ] && [ ! -L "${APP_PATH}/wp-content/cache" ]; then
        mkdir -p "${CACHE_PATH}"
        if [ "$(ls -A ${APP_PATH}/wp-content/cache 2>/dev/null)" ]; then
            cp -a "${APP_PATH}/wp-content/cache/." "${CACHE_PATH}/"
        fi
        rm -rf "${APP_PATH}/wp-content/cache"
    fi
    
    if [ -L "${APP_PATH}/wp-content/cache" ]; then
        rm -f "${APP_PATH}/wp-content/cache"
    fi

    ln -sf "${CACHE_PATH}" "${APP_PATH}/wp-content/cache"
    verbose_log "Cache symlink created"
fi

if [ -d "${APP_PATH}/wp-content" ]; then
    if [ -d "${APP_PATH}/wp-content/uploads" ] && [ ! -L "${APP_PATH}/wp-content/uploads" ]; then
        mkdir -p "${UPLOADS_PATH}"
        if [ "$(ls -A ${APP_PATH}/wp-content/uploads 2>/dev/null)" ]; then
            cp -a "${APP_PATH}/wp-content/uploads/." "${UPLOADS_PATH}/"
        fi
        rm -rf "${APP_PATH}/wp-content/uploads"
    fi
    
    if [ -L "${APP_PATH}/wp-content/uploads" ]; then
        rm -f "${APP_PATH}/wp-content/uploads"
    fi

    ln -sf "${UPLOADS_PATH}" "${APP_PATH}/wp-content/uploads"
    verbose_log "Uploads symlink created"
fi

if [ -f "/etc/cron.d/presshost.tpl" ]; then
    envsubst '$APP_PATH $LOGS_PATH' < /etc/cron.d/presshost.tpl > /etc/cron.d/presshost
    chmod 644 /etc/cron.d/presshost
    chown root:root /etc/cron.d/presshost
    verbose_log "PressHost cron configured"
fi

find /etc -name "*.tpl" -type f -delete 2>/dev/null || true

fast-chown "${APP_PATH}"

verbose_log "PressHost Ready!"

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

