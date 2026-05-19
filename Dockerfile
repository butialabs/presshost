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
ARG NGINX_VERSION=1.26.3-3+deb13u5
ARG COMPOSER_VERSION=2.9.8
ARG WPCLI_VERSION=2.12.0
ARG S6_OVERLAY_VERSION=3.2.3.0
ARG SUPERCRONIC_VERSION=0.2.45

ENV TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LOG_LEVEL=WARN \
    PHP_VERSION=${PHP_VERSION} \
    NGINX_VERSION=${NGINX_VERSION} \
    APP_PATH=/site/press \
    APP_USER=www-data \
    APP_GROUP=www-data \
    UPLOADS_PATH=/site/uploads \
    CACHE_PATH=/site/cache \
    LOGS_PATH=/site/logs \
    NGINX_HTTP_PORT=80 \
    NGINX_HTTPS_PORT=443 \
    PHP_MAX_EXECUTION_TIME=120 \
    PHP_MAX_INPUT_TIME=120 \
    PHP_MAX_INPUT_VARS=3000 \
    PHP_MEMORY_LIMIT=512M \
    PHP_POST_MAX_SIZE=64M \
    PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_DEFAULT_SOCKET_TIMEOUT=60 \
    PHP_OUTPUT_BUFFERING=4096 \
    PHP_PM=auto \
    PHP_PM_MAX_CHILDREN=auto \
    PHP_PM_START_SERVERS=10 \
    PHP_PM_MIN_SPARE_SERVERS=10 \
    PHP_PM_MAX_SPARE_SERVERS=35 \
    PHP_PM_MAX_REQUESTS=500 \
    PHP_PM_PROCESS_IDLE_TIMEOUT=10s \
    PHP_FPM_REQUEST_TERMINATE_TIMEOUT=60 \
    PHP_FPM_REQUEST_SLOWLOG_TIMEOUT=5s \
    PHP_FPM_EMERGENCY_RESTART_THRESHOLD=10 \
    PHP_FPM_EMERGENCY_RESTART_INTERVAL=1m \
    PHP_FPM_PROCESS_CONTROL_TIMEOUT=10s \
    PHP_FPM_LISTEN_BACKLOG=65535 \
    PHP_FPM_RLIMIT_FILES=65535 \
    PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_MEMORY=256 \
    PHP_OPCACHE_INTERNED_STRINGS=16 \
    PHP_OPCACHE_MAX_FILES=20000 \
    PHP_OPCACHE_REVALIDATE_FREQ=2 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
    PHP_OPCACHE_JIT=off \
    PHP_OPCACHE_JIT_BUFFER_SIZE=128M \
    PHP_DISABLE_FUNCTIONS="exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,parse_ini_file,show_source,pcntl_exec" \
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
    NGINX_CACHE_SPLIT_MOBILE=false \
    NGINX_CLIENT_BODY_BUFFER_SIZE=128k \
    NGINX_CLIENT_HEADER_BUFFER_SIZE=1k \
    NGINX_LARGE_CLIENT_HEADER_BUFFERS="4 16k" \
    NGINX_OUTPUT_BUFFERS="1 32k" \
    NGINX_FASTCGI_BUFFER_SIZE=32k \
    NGINX_FASTCGI_BUFFERS="16 16k" \
    NGINX_FASTCGI_BUSY_BUFFERS_SIZE=64k \
    NGINX_FASTCGI_CONNECT_TIMEOUT=60s \
    NGINX_FASTCGI_SEND_TIMEOUT=60s \
    NGINX_FASTCGI_READ_TIMEOUT=300s \
    NGINX_KEEPALIVE_TIMEOUT=65s \
    NGINX_KEEPALIVE_REQUESTS=1000 \
    NGINX_CLIENT_BODY_TIMEOUT=60s \
    NGINX_CLIENT_HEADER_TIMEOUT=30s \
    NGINX_SEND_TIMEOUT=60s \
    NGINX_GZIP_COMP_LEVEL=6 \
    NGINX_BROTLI_COMP_LEVEL=4 \
    NGINX_RATE_LIMIT=30r/s \
    NGINX_RATE_BURST=60 \
    NGINX_CONN_LIMIT=50 \
    NGINX_HTTP3=false \
    NGINX_SSL_STAPLING="off" \
    NGINX_SSL_STAPLING_VERIFY="off" \
    SSL_CERT_PATH="/site/ssl/server.crt" \
    SSL_PRIVATE_PATH="/site/ssl/server.key" \
    SSL_TRUSTED_CERT_PATH="/site/ssl/server.crt" \
    LOG_MAX_SIZE=100M \
    LOG_MAX_AGE=7 \
    WP_CLI_DIR=/.wp-cli \
    WP_CLI_CACHE_DIR=/.wp-cli/cache \
    WP_CLI_PACKAGES_DIR=/.wp-cli/packages \
    HOME=/home/www-data \
    S6_KEEP_ENV=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) S6_ARCH="x86_64"; SUPERCRONIC_ARCH="amd64" ;; \
        arm64) S6_ARCH="aarch64"; SUPERCRONIC_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        unzip \
        logrotate \
        mariadb-client \
        procps \
        nano \
        whiptail \
        gettext-base \
        openssl \
        libfcgi-bin \
        lsb-release \
        gnupg \
        xz-utils; \
    curl -fsSL https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg; \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
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
        libnginx-mod-http-cache-purge; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" -o /tmp/s6-overlay-noarch.tar.xz; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" -o /tmp/s6-overlay-arch.tar.xz; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" -o /tmp/s6-overlay-symlinks-noarch.tar.xz; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" -o /tmp/s6-overlay-symlinks-arch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz; \
    rm -f /tmp/s6-overlay-*.tar.xz; \
    curl -fsSL "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${SUPERCRONIC_ARCH}" \
        -o /usr/local/bin/supercronic; \
    chmod +x /usr/local/bin/supercronic; \
    curl -fsSL -o /usr/local/bin/composer https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar; \
    chmod +x /usr/local/bin/composer; \
    curl -fsSL -o /usr/local/bin/wp https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar; \
    chmod +x /usr/local/bin/wp; \
    apt-get purge -y --auto-remove lsb-release gnupg xz-utils; \
    rm -rf /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*; \
    ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm; \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN set -eux; \
    mkdir -p \
        /site/press /site/uploads /site/cache /site/logs /site/ssl \
        ${WP_CLI_DIR} ${WP_CLI_CACHE_DIR} ${WP_CLI_PACKAGES_DIR} \
        /run/nginx /run/php \
        /etc/presshost; \
    chown -R www-data:www-data \
        /site \
        ${WP_CLI_DIR} \
        /run/nginx /run/php

COPY --chmod=755 rootfs/usr/local/bin/ /usr/local/bin/

# Copy s6-overlay files
COPY rootfs/etc/s6-overlay/ /etc/s6-overlay/
RUN set -eux; \
    chmod +x /etc/s6-overlay/scripts/* \
    && find /etc/s6-overlay/s6-rc.d -name "run" -exec chmod +x {} \; \
    && find /etc/s6-overlay/s6-rc.d -name "up" -exec chmod +x {} \;

# Copy NGINX files
COPY rootfs/etc/nginx/ /etc/nginx/

# Copy supercronic crontab
COPY rootfs/etc/presshost/ /etc/presshost/

# Copy PHP files
COPY rootfs/etc/php/fpm/pool.d/www.conf.tpl /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf.tpl
COPY rootfs/etc/php/fpm/conf.d/99-presshost.ini.tpl /etc/php/${PHP_VERSION}/fpm/conf.d/99-presshost.ini.tpl
COPY rootfs/etc/php/fpm/php-fpm-emergency.conf.tpl /etc/php/${PHP_VERSION}/fpm/php-fpm-emergency.conf.tpl

# Copy Logrotate files
COPY rootfs/etc/logrotate.d/ /etc/logrotate.d/

RUN ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone

# Copy sample files
COPY rootfs/site/press/index.php /tmp/index.php
COPY rootfs/site/press/wp-config.php /tmp/wp-config.php

WORKDIR /site/press

EXPOSE 80
EXPOSE 443

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /etc/s6-overlay/scripts/healthcheck-all || exit 1

ENTRYPOINT ["/init"]
