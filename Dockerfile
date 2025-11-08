# PressHost Docker Container
# Based on shinsenter/php:8.4-fpm-nginx for optimized and flexible WordPress/ClassicPress hosting

FROM shinsenter/php:8.4-fpm-nginx

# Metadata
LABEL maintainer="Butiá Labs <contato@butialabs.com>"
LABEL description="PressHost - Production-ready WordPress/ClassicPress hosting with NGINX, PHP 8.4"
LABEL version="1.0"
LABEL org.opencontainers.image.source="https://github.com/butialabs/presshost"

# ==========================================
# DIRECTORY STRUCTURE
# ==========================================
ENV APP_PATH=/site/press
ENV DOCUMENT_ROOT=/site/press
ENV APP_USER=www-data
ENV APP_GROUP=www-data

# ==========================================
# PHP CONFIGURATION
# ==========================================
# Enable runtime PHP configuration
ENV ALLOW_RUNTIME_PHP_ENVVARS=1

# Performance settings
ENV PHP_MAX_EXECUTION_TIME=600
ENV PHP_MAX_INPUT_TIME=400
ENV PHP_MEMORY_LIMIT=512M
ENV PHP_POST_MAX_SIZE=64M
ENV PHP_UPLOAD_MAX_FILESIZE=64M
ENV PHP_MAX_FILE_UPLOADS=20
ENV PHP_MAX_INPUT_VARS=3000

# Error handling
ENV PHP_DISPLAY_ERRORS=Off
ENV PHP_LOG_ERRORS=On
ENV PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT"

# Security
ENV PHP_EXPOSE_PHP=Off
ENV PHP_ALLOW_URL_FOPEN=On
ENV PHP_ALLOW_URL_INCLUDE=Off

# OPcache configuration
ENV PHP_OPCACHE_ENABLE=1
ENV PHP_OPCACHE_ENABLE_CLI=0
ENV PHP_OPCACHE_MEMORY_CONSUMPTION=512
ENV PHP_OPCACHE_MAX_ACCELERATED_FILES=50000
ENV PHP_OPCACHE_REVALIDATE_FREQ=0
ENV PHP_OPCACHE_CONSISTENCY_CHECKS=1

# APCu configuration
ENV PHP_APC_ENABLED=1
ENV PHP_APC_SHM_SIZE=1024M
ENV PHP_APC_MAX_FILE_SIZE=10M

# Session configuration
ENV PHP_SESSION_SAVE_HANDLER=files
ENV PHP_SESSION_SAVE_PATH=/tmp

# Date/Timezone
ENV TZ=UTC

# Output buffering
ENV PHP_OUTPUT_BUFFERING=4096
ENV PHP_IMPLICIT_FLUSH=Off

# Zlib compression
ENV PHP_ZLIB_OUTPUT_COMPRESSION=On
ENV PHP_ZLIB_OUTPUT_COMPRESSION_LEVEL=6

# MySQL/MySQLi
ENV PHP_MYSQLI_DEFAULT_SOCKET=/var/run/mysqld/mysqld.sock
ENV PHP_MYSQLI_RECONNECT=On
ENV PHP_MYSQLI_CACHE_SIZE=2000

# Realpath cache
ENV PHP_REALPATH_CACHE_SIZE=16K
ENV PHP_REALPATH_CACHE_TTL=600

# PCRE settings
ENV PHP_PCRE_BACKTRACK_LIMIT=1000000
ENV PHP_PCRE_RECURSION_LIMIT=100000
ENV PHP_PCRE_JIT=1

# ==========================================
# CRON
# ==========================================
ENV ENABLE_CRONTAB=1
ENV CRONTAB_HOME=/site/press

# ==========================================
# INSTALLATION
# ==========================================
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Essential tools
    curl \
    ca-certificates \
    gnupg2 \
    # WordPress utilities
    default-mysql-client \
    unzip \
    nano \
    less \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install required PHP extensions using phpaddmod
RUN phpaddmod \
    bcmath \
    gd \
    imagick \
    intl \
    mysqli \
    opcache \
    zip \
    apcu \
    redis \
    soap \
    imap \
    xmlrpc

# Install WP-CLI using shinsenter's best practices
ARG WPCLI_URL=https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
ARG WPCLI_PATH=/usr/local/bin/wp-cli

RUN <<'EOF'
echo 'Installing WP-CLI...'
[ -z "$DEBUG" ] || set -ex && set -e

# Set WP-CLI environment defaults
env-default "alias wp-cli='$WPCLI_PATH --allow-root'"
env-default INITIAL_PROJECT     'manual'
env-default WP_CLI_DIR          '/.wp-cli'
env-default WP_CLI_CACHE_DIR    '$WP_CLI_DIR/cache/'
env-default WP_CLI_PACKAGES_DIR '$WP_CLI_DIR/packages/'
env-default WP_CLI_CONFIG_PATH  '$WP_CLI_DIR/config.yml'
env-default WP_DEBUG            '$(is-debug && echo 1 || echo 0)'
env-default WP_DEBUG_LOG        '$(log-path stdout)'
env-default WORDPRESS_DEBUG     '$(is-debug && echo 1 || echo 0)'

# Download and install WP-CLI
php -r "copy('$WPCLI_URL', '$WPCLI_PATH');" && chmod +xr "$WPCLI_PATH"
$WPCLI_PATH --allow-root --version

# Create wp command alias
web-cmd wp "$WPCLI_PATH --allow-root"
EOF

# ==========================================
# DIRECTORY STRUCTURE
# ==========================================
RUN mkdir -p \
    /site/press \
    /site/uploads \
    /site/cache/page \
    /site/cache/minify \
    /site/cache/object \
    /site/cache/db \
    /site/cache/tmp \
    /var/log/presshost

# Set permissions for directories
RUN chown -R www-data:www-data \
    /site/uploads \
    /site/cache \
    /var/log/presshost \
    && chmod -R 755 /site/cache \
    && chmod 775 /site/cache/tmp

# ==========================================
# NGINX CONFIGURATION
# ==========================================
# Copy custom NGINX configurations to conf.d
COPY nginx/conf.d/ /etc/nginx/conf.d/

# Copy NGINX templates
COPY nginx/*.tpl /nginx/

# ==========================================
# HOOKS AND SCRIPTS
# ==========================================
# Copy common utilities script
COPY press/common-utils.sh /press/
RUN chmod +x /press/common-utils.sh

# Copy hooks to /startup/ (executed by shinsenter/php on container start)
COPY hooks/ /startup/
RUN chmod +x /startup/*.sh

# Copy installers for WordPress/ClassicPress
COPY press/install-*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-*.sh \
    && ln -sf /usr/local/bin/install-wordpress.sh /usr/local/bin/install-wordpress \
    && ln -sf /usr/local/bin/install-classicpress.sh /usr/local/bin/install-classicpress

# ==========================================
# WP-CONFIG
# ==========================================
# Download wp-config.php from official WordPress Docker repository
ADD --chown=www-data:www-data https://raw.githubusercontent.com/docker-library/wordpress/master/wp-config-docker.php /site/press/wp-config.php

# ==========================================
# CRONTAB
# ==========================================
# Copy crontab configuration
COPY crontab.d/presshost /etc/crontab.d/presshost
RUN chmod 0644 /etc/crontab.d/presshost

# ==========================================
# EXPOSE PORTS
# ==========================================
EXPOSE 80
EXPOSE 443

# ==========================================
# VOLUMES
# ==========================================
VOLUME ["/site/press", "/site/uploads", "/site/cache", "/var/log"]

# ==========================================
# WORKING DIR
# ==========================================
WORKDIR /site