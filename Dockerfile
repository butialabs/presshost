FROM debian:trixie-slim
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

LABEL maintainer="Butiá Labs <mecairam@butialabs.com>" \
    org.opencontainers.image.title="PressHost" \
    org.opencontainers.image.description="Docker image for WordPress and ClassicPress hosting with NGINX and PHP 8.4." \
    org.opencontainers.image.url="https://github.com/butialabs/presshost" \
    org.opencontainers.image.source="https://github.com/butialabs/presshost" \
    org.opencontainers.image.vendor="Butiá Labs" \
    org.opencontainers.image.licenses="MIT"

ARG PHP_VERSION=8.4
ARG NGINX_VERSION=1.26.3-3+deb13u2
ARG COMPOSER_VERSION=2.9.4
ARG WPCLI_VERSION=2.12.0
ARG S6_OVERLAY_VERSION=3.2.2.0

ENV TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    VERBOSE=false \
    APP_PATH=/site/press \
    APP_USER=www-data \
    APP_GROUP=www-data \
    UPLOADS_PATH=/site/uploads \
    CACHE_PATH=/site/cache \
    LOGS_PATH=/site/logs \
    PHP_MAX_EXECUTION_TIME=120 \
    PHP_MAX_INPUT_TIME=120 \
    PHP_MAX_INPUT_VARS=3000 \
    PHP_MEMORY_LIMIT=512M \
    PHP_POST_MAX_SIZE=64M \
    PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_DEFAULT_SOCKET_TIMEOUT=60 \
    PHP_OUTPUT_BUFFERING=4096 \
    PHP_PM=dynamic \
    PHP_PM_MAX_CHILDREN=50 \
    PHP_PM_START_SERVERS=10 \
    PHP_PM_MIN_SPARE_SERVERS=10 \
    PHP_PM_MAX_SPARE_SERVERS=35 \
    PHP_PM_MAX_REQUESTS=1000 \
    PHP_PM_PROCESS_IDLE_TIMEOUT=10s \
    PHP_FPM_REQUEST_TERMINATE_TIMEOUT=300 \
    PHP_FPM_LISTEN_BACKLOG=65535 \
    PHP_FPM_RLIMIT_FILES=65535 \
    PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_MEMORY=256 \
    PHP_OPCACHE_INTERNED_STRINGS=16 \
    PHP_OPCACHE_MAX_FILES=20000 \
    PHP_OPCACHE_REVALIDATE_FREQ=2 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
    PHP_OPCACHE_JIT=tracing \
    PHP_OPCACHE_JIT_BUFFER_SIZE=128M \
    PHP_SESSION_COOKIE_HTTPONLY=1 \
    PHP_SESSION_COOKIE_SECURE=1 \
    PHP_SESSION_USE_STRICT_MODE=1 \
    PHP_APC_ENABLED=1 \
    PHP_APC_SHM_SIZE=64M \
    PHP_APC_TTL=7200 \
    PHP_APC_ENABLE_CLI=0 \
    PHP_REALPATH_CACHE_SIZE=4096K \
    PHP_REALPATH_CACHE_TTL=600 \
    NGINX_CLIENT_MAX_BODY_SIZE=64m \
    NGINX_CACHE=false \
    NGINX_CACHE_MAX_SIZE=512m \
    NGINX_CACHE_INACTIVE=60m \
    NGINX_CLIENT_BODY_BUFFER_SIZE=128k \
    NGINX_CLIENT_HEADER_BUFFER_SIZE=1k \
    NGINX_LARGE_CLIENT_HEADER_BUFFERS="4 16k" \
    NGINX_OUTPUT_BUFFERS="1 32k" \
    NGINX_FASTCGI_BUFFER_SIZE=32k \
    NGINX_FASTCGI_BUFFERS="16 16k" \
    NGINX_FASTCGI_BUSY_BUFFERS_SIZE=64k \
    NGINX_FASTCGI_CONNECT_TIMEOUT=300s \
    NGINX_FASTCGI_SEND_TIMEOUT=300s \
    NGINX_FASTCGI_READ_TIMEOUT=300s \
    NGINX_KEEPALIVE_TIMEOUT=65s \
    NGINX_KEEPALIVE_REQUESTS=1000 \
    NGINX_CLIENT_BODY_TIMEOUT=60s \
    NGINX_CLIENT_HEADER_TIMEOUT=120s \
    NGINX_SEND_TIMEOUT=60s \
    NGINX_SSL_STAPLING="off" \
    NGINX_SSL_STAPLING_VERIFY="off" \
    SSL_CERT_PATH="/etc/nginx/server.crt" \
    SSL_PRIVATE_PATH="/etc/nginx/server.key" \
    SSL_TRUSTED_CERT_PATH="/etc/nginx/server.crt" \
    ALLOW_RUNTIME_PHP_ENVVARS=true \
    LOG_MAX_SIZE=100M \
    LOG_MAX_AGE=1 \
    WP_CLI_DIR=/.wp-cli \
    WP_CLI_CACHE_DIR=/.wp-cli/cache \
    WP_CLI_PACKAGES_DIR=/.wp-cli/packages

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    lsb-release \
    debian-archive-keyring \
    gnupg \
    unzip \
    xz-utils \
    cron \
    logrotate \
    mariadb-client \
    htop \
    procps \
    nano \
    whiptail \
    gettext-base

# Add Sury PHP repository
RUN curl -fsSL https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Install PHP and NGINX
RUN apt-get update && apt-get install -y --no-install-recommends \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-exif \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-memcached \
    nginx=${NGINX_VERSION} \
    libnginx-mod-http-brotli-filter \
    libnginx-mod-http-brotli-static \
    libnginx-mod-http-cache-purge \
    && rm -rf /etc/nginx/sites-enabled/* /etc/nginx/sites-available/* \
    && rm -rf /var/lib/apt/lists/*

# Install s6-overlay v3
RUN set -eux; \
    S6_ARCH=""; \
    case "${TARGETARCH}" in \
        amd64) S6_ARCH="x86_64" ;; \
        arm64) S6_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" -o /tmp/s6-overlay-noarch.tar.xz; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" -o /tmp/s6-overlay-arch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz; \
    rm -f /tmp/s6-overlay-*.tar.xz

# Install composer
RUN curl -fsSL -o /usr/local/bin/composer https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar \
    && chmod +x /usr/local/bin/composer


# Install WP-CLI
RUN curl -fsSL -o /usr/local/bin/wp https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar \
    && chmod +x /usr/local/bin/wp

# Create base directories
RUN mkdir -p /site/press /site/uploads /site/cache /site/logs $WP_CLI_DIR $WP_CLI_CACHE_DIR $WP_CLI_PACKAGES_DIR && \
    if [ "${NGINX_CACHE}" = "true" ]; then \
        mkdir -p "${CACHE_PATH}/nginx"; \
        chown -R ${APP_USER}:${APP_GROUP} "${CACHE_PATH}/nginx"; \
    fi

COPY --chmod=755 rootfs/usr/local/bin/ /usr/local/bin/
COPY rootfs/etc/nginx/ /etc/nginx/
RUN chmod 644 /etc/nginx/server.crt && chmod 600 /etc/nginx/server.key && chmod 644 /etc/nginx/dhparam.pem

# Copy s6-overlay configuration
COPY rootfs/etc/s6-overlay/ /etc/s6-overlay/
RUN chmod +x /etc/s6-overlay/scripts/* \
    && find /etc/s6-overlay/s6-rc.d -name "run" -exec chmod +x {} \; \
    && find /etc/s6-overlay/s6-rc.d -name "up" -exec chmod +x {} \;

# Copy template files
COPY rootfs/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf.tpl /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf.tpl
COPY rootfs/etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini.tpl /etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini.tpl
COPY rootfs/etc/nginx/nginx.conf.tpl /etc/nginx/nginx.conf.tpl
COPY rootfs/etc/nginx/sites-enabled/presshost.conf.tpl /etc/nginx/sites-enabled/presshost.conf.tpl
COPY rootfs/etc/nginx/conf.d/cache-path.conf.tpl /etc/nginx/conf.d/cache-path.conf.tpl
COPY rootfs/etc/logrotate.d/presshost.tpl /etc/logrotate.d/presshost.tpl
COPY rootfs/etc/cron.d/presshost.tpl /etc/cron.d/presshost.tpl

# Timezone configuration
RUN if [ -n "$TZ" ] && [ -f "/usr/share/zoneinfo/$TZ" ]; then \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime; \
    echo "$TZ" > /etc/timezone; \
fi

# Process templates
RUN set -eux; \
    # Verify folders
    ls -la /etc/php/; \
    ls -la /etc/php/${PHP_VERSION}/; \
    ls -la /etc/php/${PHP_VERSION}/fpm/; \
    ls -la /etc/php/${PHP_VERSION}/fpm/pool.d/; \

    # PHP
    ## PHP_CLEAR_ENV
    if [ "${ALLOW_RUNTIME_PHP_ENVVARS}" = "true" ]; then \
        export PHP_CLEAR_ENV="no"; \
    else \
        export PHP_CLEAR_ENV="yes"; \
    fi; \
    \
    ## PHP-FPM run script
    envsubst '$PHP_VERSION' < /etc/s6-overlay/s6-rc.d/php-fpm/run.tpl > /etc/s6-overlay/s6-rc.d/php-fpm/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/php-fpm/run \
    && rm -f /etc/s6-overlay/s6-rc.d/php-fpm/run.tpl; \
    \
    ## PHP-FPM pool config
    envsubst '${APP_USER} ${APP_GROUP} ${LOGS_PATH} ${PHP_PM} ${PHP_PM_MAX_CHILDREN} ${PHP_PM_START_SERVERS} ${PHP_PM_MIN_SPARE_SERVERS} ${PHP_PM_MAX_SPARE_SERVERS} ${PHP_PM_MAX_REQUESTS} ${PHP_PM_PROCESS_IDLE_TIMEOUT} ${PHP_FPM_REQUEST_TERMINATE_TIMEOUT} ${PHP_FPM_LISTEN_BACKLOG} ${PHP_FPM_RLIMIT_FILES} ${PHP_CLEAR_ENV} ${PHP_VERSION}' \
    < /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf.tpl \
    > /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf; \
    ls -la /etc/php/${PHP_VERSION}/fpm/pool.d/; \
    \
    ## PHP ini config
    envsubst '${PHP_MAX_EXECUTION_TIME} ${PHP_MAX_INPUT_TIME} ${PHP_MAX_INPUT_VARS} ${PHP_MEMORY_LIMIT} ${PHP_POST_MAX_SIZE} ${PHP_UPLOAD_MAX_FILESIZE} ${PHP_DEFAULT_SOCKET_TIMEOUT} ${PHP_OUTPUT_BUFFERING} ${PHP_OPCACHE_ENABLE} ${PHP_OPCACHE_MEMORY} ${PHP_OPCACHE_INTERNED_STRINGS} ${PHP_OPCACHE_MAX_FILES} ${PHP_OPCACHE_REVALIDATE_FREQ} ${PHP_OPCACHE_VALIDATE_TIMESTAMPS} ${PHP_OPCACHE_JIT} ${PHP_OPCACHE_JIT_BUFFER_SIZE} ${PHP_SESSION_COOKIE_HTTPONLY} ${PHP_SESSION_COOKIE_SECURE} ${PHP_SESSION_USE_STRICT_MODE} ${PHP_APC_ENABLED} ${PHP_APC_SHM_SIZE} ${PHP_APC_TTL} ${PHP_APC_ENABLE_CLI} ${PHP_REALPATH_CACHE_SIZE} ${PHP_REALPATH_CACHE_TTL}' \
    < /etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini.tpl \
    > /etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini; \
    cp /etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-presshost.ini; \
    \
    # NGINX
    ## Config
    envsubst '${APP_USER} ${LOGS_PATH} ${NGINX_CLIENT_MAX_BODY_SIZE} ${NGINX_CLIENT_BODY_BUFFER_SIZE} ${NGINX_CLIENT_HEADER_BUFFER_SIZE} ${NGINX_LARGE_CLIENT_HEADER_BUFFERS} ${NGINX_OUTPUT_BUFFERS} ${NGINX_KEEPALIVE_TIMEOUT} ${NGINX_KEEPALIVE_REQUESTS} ${NGINX_CLIENT_BODY_TIMEOUT} ${NGINX_CLIENT_HEADER_TIMEOUT} ${NGINX_SEND_TIMEOUT} ${NGINX_FASTCGI_CONNECT_TIMEOUT} ${NGINX_FASTCGI_SEND_TIMEOUT} ${NGINX_FASTCGI_READ_TIMEOUT} ${NGINX_FASTCGI_BUFFER_SIZE} ${NGINX_FASTCGI_BUFFERS} ${NGINX_FASTCGI_BUSY_BUFFERS_SIZE}' \
    < /etc/nginx/nginx.conf.tpl \
    > /etc/nginx/nginx.conf; \
    \
    ## Site config
    envsubst '${APP_PATH} ${LOGS_PATH} ${SSL_CERT_PATH} ${SSL_PRIVATE_PATH} ${SSL_TRUSTED_CERT_PATH} ${NGINX_SSL_STAPLING} ${NGINX_SSL_STAPLING_VERIFY} ${NGINX_FASTCGI_BUFFER_SIZE} ${NGINX_FASTCGI_BUFFERS} ${NGINX_FASTCGI_BUSY_BUFFERS_SIZE} ${NGINX_FASTCGI_CONNECT_TIMEOUT} ${NGINX_FASTCGI_SEND_TIMEOUT} ${NGINX_FASTCGI_READ_TIMEOUT} ${PHP_VERSION}' \
    < /etc/nginx/sites-enabled/presshost.conf.tpl \
    > /etc/nginx/sites-enabled/presshost.conf; \
    \
    ## Cache config
    if [ "${NGINX_CACHE}" = "true" ]; then \
        envsubst '${CACHE_PATH} ${NGINX_CACHE_MAX_SIZE} ${NGINX_CACHE_INACTIVE}' \
        < /etc/nginx/conf.d/cache-path.conf.tpl \
        > /etc/nginx/conf.d/cache-path.conf; \
    else \
        echo "# Cache - Disabled" > /etc/nginx/conf.d/cache-fastcgi.conf; \
        echo "# Cache - Disabled" > /etc/nginx/conf.d/cache-path.conf; \
        echo "# Cache - Disabled" > /etc/nginx/conf.d/cache-purge.conf; \
    fi; \
    \
    # Logrotate config
    envsubst '${LOGS_PATH} ${LOG_MAX_SIZE} ${LOG_MAX_AGE}' \
    < /etc/logrotate.d/presshost.tpl \
    > /etc/logrotate.d/presshost; \
    \
    # Cron config
    envsubst '${APP_PATH} ${LOGS_PATH}' \
    < /etc/cron.d/presshost.tpl \
    > /etc/cron.d/presshost; \
    chmod 644 /etc/cron.d/presshost; \
    chown root:root /etc/cron.d/presshost; \
    # Remove templates
    find /etc -name "*.tpl" -type f -delete;

# Copy sample files
COPY /rootfs/site/press/index.php /tmp/index.php
COPY /rootfs/site/press/wp-config.php /tmp/wp-config.php

# Copy Presshost Init
COPY rootfs/etc/s6-overlay/scripts/presshost-init /etc/s6-overlay/scripts/presshost-init
RUN chmod +x /etc/s6-overlay/scripts/presshost-init && \
    ls -la /etc/s6-overlay/scripts/presshost-init

WORKDIR /site/press

EXPOSE 80
EXPOSE 443

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost/ -o /dev/null || exit 1

ENTRYPOINT ["/init"]