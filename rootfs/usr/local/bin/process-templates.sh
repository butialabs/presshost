#!/bin/bash
set -e

SCRIPT_NAME="PROCESS-TEMPLATES"
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/common-utils.sh" || { echo "ERROR: Failed to load common utilities" >&2; exit 1; }

info "Starting template processing..."

PHP_VERSION=${PHP_VERSION}

debug "Using PHP_VERSION: ${PHP_VERSION}"
debug "Using SSL_CERT_PATH: ${SSL_CERT_PATH}"

if [ "${ALLOW_RUNTIME_PHP_ENVVARS}" = "true" ]; then
    export PHP_CLEAR_ENV="no"
else
    export PHP_CLEAR_ENV="yes"
fi

info "Processing PHP-FPM run script..."
envsubst '$PHP_VERSION' < /etc/s6-overlay/s6-rc.d/php-fpm/run.tpl > /etc/s6-overlay/s6-rc.d/php-fpm/run
chmod +x /etc/s6-overlay/s6-rc.d/php-fpm/run

info "Processing PHP-FPM pool config..."
envsubst '${APP_USER} ${APP_GROUP} ${LOGS_PATH} ${PHP_PM} ${PHP_PM_MAX_CHILDREN} ${PHP_PM_START_SERVERS} ${PHP_PM_MIN_SPARE_SERVERS} ${PHP_PM_MAX_SPARE_SERVERS} ${PHP_PM_MAX_REQUESTS} ${PHP_PM_PROCESS_IDLE_TIMEOUT} ${PHP_FPM_REQUEST_TERMINATE_TIMEOUT} ${PHP_FPM_LISTEN_BACKLOG} ${PHP_FPM_RLIMIT_FILES} ${PHP_CLEAR_ENV} ${PHP_VERSION}' \
< /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf.tpl \
> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

info "Processing PHP ini config..."
envsubst '${PHP_MAX_EXECUTION_TIME} ${PHP_MAX_INPUT_TIME} ${PHP_MAX_INPUT_VARS} ${PHP_MEMORY_LIMIT} ${PHP_POST_MAX_SIZE} ${PHP_UPLOAD_MAX_FILESIZE} ${PHP_DEFAULT_SOCKET_TIMEOUT} ${PHP_OUTPUT_BUFFERING} ${PHP_OPCACHE_ENABLE} ${PHP_OPCACHE_MEMORY} ${PHP_OPCACHE_INTERNED_STRINGS} ${PHP_OPCACHE_MAX_FILES} ${PHP_OPCACHE_REVALIDATE_FREQ} ${PHP_OPCACHE_VALIDATE_TIMESTAMPS} ${PHP_OPCACHE_JIT} ${PHP_OPCACHE_JIT_BUFFER_SIZE} ${PHP_SESSION_COOKIE_HTTPONLY} ${PHP_SESSION_COOKIE_SECURE} ${PHP_SESSION_USE_STRICT_MODE} ${PHP_APC_ENABLED} ${PHP_APC_SHM_SIZE} ${PHP_APC_TTL} ${PHP_APC_ENABLE_CLI} ${PHP_REALPATH_CACHE_SIZE} ${PHP_REALPATH_CACHE_TTL}' \
< /etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini.tpl \
> /etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini

cp /etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-presshost.ini

info "Processing NGINX config..."
envsubst '${APP_USER} ${LOGS_PATH} ${NGINX_CLIENT_MAX_BODY_SIZE} ${NGINX_CLIENT_BODY_BUFFER_SIZE} ${NGINX_CLIENT_HEADER_BUFFER_SIZE} ${NGINX_LARGE_CLIENT_HEADER_BUFFERS} ${NGINX_OUTPUT_BUFFERS} ${NGINX_KEEPALIVE_TIMEOUT} ${NGINX_KEEPALIVE_REQUESTS} ${NGINX_CLIENT_BODY_TIMEOUT} ${NGINX_CLIENT_HEADER_TIMEOUT} ${NGINX_SEND_TIMEOUT} ${NGINX_FASTCGI_CONNECT_TIMEOUT} ${NGINX_FASTCGI_SEND_TIMEOUT} ${NGINX_FASTCGI_READ_TIMEOUT} ${NGINX_FASTCGI_BUFFER_SIZE} ${NGINX_FASTCGI_BUFFERS} ${NGINX_FASTCGI_BUSY_BUFFERS_SIZE}' \
< /etc/nginx/nginx.conf.tpl \
> /etc/nginx/nginx.conf

info "Processing NGINX site config..."
envsubst '${APP_PATH} ${LOGS_PATH} ${SSL_CERT_PATH} ${SSL_PRIVATE_PATH} ${SSL_TRUSTED_CERT_PATH} ${NGINX_SSL_STAPLING} ${NGINX_SSL_STAPLING_VERIFY} ${NGINX_FASTCGI_BUFFER_SIZE} ${NGINX_FASTCGI_BUFFERS} ${NGINX_FASTCGI_BUSY_BUFFERS_SIZE} ${NGINX_FASTCGI_CONNECT_TIMEOUT} ${NGINX_FASTCGI_SEND_TIMEOUT} ${NGINX_FASTCGI_READ_TIMEOUT} ${PHP_VERSION}' \
< /etc/nginx/sites-enabled/presshost.conf.tpl \
> /etc/nginx/sites-enabled/presshost.conf

info "Processing NGINX cache config..."
if [ "${NGINX_CACHE}" = "true" ]; then
    envsubst '${CACHE_PATH} ${NGINX_CACHE_MAX_SIZE} ${NGINX_CACHE_INACTIVE}' \
    < /etc/nginx/conf.d/cache-path.conf.tpl \
    > /etc/nginx/conf.d/cache-path.conf
else
    echo "# Cache - Disabled" > /etc/nginx/conf.d/cache-fastcgi.conf
    echo "# Cache - Disabled" > /etc/nginx/conf.d/cache-path.conf
    echo "# Cache - Disabled" > /etc/nginx/conf.d/cache-purge.conf
fi

info "Processing logrotate config..."
envsubst '${LOGS_PATH} ${LOG_MAX_SIZE} ${LOG_MAX_AGE}' \
< /etc/logrotate.d/presshost.tpl \
> /etc/logrotate.d/presshost

info "Processing cron config..."
envsubst '${APP_PATH} ${LOGS_PATH}' \
< /etc/cron.d/presshost.tpl \
> /etc/cron.d/presshost
chmod 644 /etc/cron.d/presshost
chown root:root /etc/cron.d/presshost

info "Removing template files..."
find /etc -name "*.tpl" -type f -delete

success "Template processing completed successfully!"