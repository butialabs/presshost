#!/bin/bash
set -e

verbose_log() {
    [ "${VERBOSE}" = "true" ] && echo "$@" || true
}

autoenv_tpl() {
    local template="$1"
    local output="$2"
    
    if [ ! -f "$template" ]; then
        return 1
    fi
    
    local vars
    vars=$(grep -oE '\$\{?[A-Z_][A-Z0-9_]*\}?' "$template" 2>/dev/null | \
           sed 's/[${}]//g' | sort -u | \
           while read -r var; do
               if [ -n "${!var+x}" ]; then
                   echo -n "\$$var "
               fi
           done)
    
    if [ -n "$vars" ]; then
        envsubst "$vars" < "$template" > "$output"
    else
        cp "$template" "$output"
    fi
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
    autoenv_tpl /etc/logrotate.d/presshost.tpl /etc/logrotate.d/presshost
    verbose_log "Log rotation configured"
fi

if [ "${ALLOW_RUNTIME_PHP_ENVVARS}" = "true" ]; then
    export PHP_CLEAR_ENV="no"
else
    export PHP_CLEAR_ENV="yes"
fi

if [ -f "/etc/php/8.4/fpm/pool.d/www.conf.tpl" ]; then
    autoenv_tpl /etc/php/8.4/fpm/pool.d/www.conf.tpl /etc/php/8.4/fpm/pool.d/www.conf
    verbose_log "PHP-FPM pool configuration generated"
fi

if [ -f "/etc/php/8.4/fpm/conf.d/99-presshost.ini.tpl" ]; then
    autoenv_tpl /etc/php/8.4/fpm/conf.d/99-presshost.ini.tpl /etc/php/8.4/fpm/conf.d/99-presshost.ini
    cp /etc/php/8.4/fpm/conf.d/99-presshost.ini /etc/php/8.4/cli/conf.d/99-presshost.ini
    verbose_log "PHP ini configuration generated"
fi

if [ -f "/etc/nginx/nginx.conf.tpl" ]; then
    autoenv_tpl /etc/nginx/nginx.conf.tpl /etc/nginx/nginx.conf
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
    autoenv_tpl /etc/nginx/sites-enabled/presshost.conf.tpl /etc/nginx/sites-enabled/presshost.conf
    verbose_log "NGINX site configuration generated"
fi

if [ -f "/etc/supervisor/supervisord.conf.tpl" ]; then
    autoenv_tpl /etc/supervisor/supervisord.conf.tpl /etc/supervisor/supervisord.conf
    verbose_log "Supervisor configuration generated"
fi

for tpl in /etc/supervisor/conf.d/*.tpl; do
    if [ -f "$tpl" ]; then
        conf="${tpl%.tpl}"
        autoenv_tpl "$tpl" "$conf"
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

