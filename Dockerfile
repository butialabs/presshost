# PressHost Docker Container with NGINX, PHP 8.4, and SSL
FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=8.4
ENV NGINX_VERSION=1.28.0-6ppa~stable
ENV WP_CLI_VERSION=2.12.0

# Install system dependencies and repositories
RUN apt-get update && apt-get install -y \
    # Basic system utilities
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    supervisor \
    gzip \
    less \
    default-mysql-client \
    unzip \
    openssl \
    cron \
    nano \
    logrotate \
    jq

# Add PHP repository
RUN curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/php-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/php-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Add WordOps repository for nginx-wo from OpenSUSE Build Service
# Using trusted=yes to bypass expired GPG key verification
RUN echo "deb [trusted=yes] https://download.opensuse.org/repositories/home:virtubox:WordOps/Debian_12/ /" > /etc/apt/sources.list.d/wordops-nginx-wo.list

RUN apt-get update

# Install WordOps custom NGINX
RUN apt-get install -y \
    nginx-custom=${NGINX_VERSION} \
    nginx-wo=${NGINX_VERSION}

# Install PHP 8.4 with PressHost recommended packages
RUN apt-get install -y \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-xmlrpc \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-dev \
    php${PHP_VERSION}-imap \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-enchant \
    php${PHP_VERSION}-ssh2 \
    php${PHP_VERSION}-apcu

# Install Certbot with NGINX support
RUN apt-get install -y \
    certbot \
    python3-certbot-nginx

# Update ca-certificates and ensure proper SSL setup
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && rm -rf /var/cache/apt/archives/*

# Install WP-CLI
RUN curl -L https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp \
    && wp --info --allow-root

# Create required directory structure
RUN mkdir -p \
    /site/press \
    /site/uploads \
    /etc/nginx/ssl \
    /etc/ssl/certs \
    /var/www/certbot \
    /etc/letsencrypt \
    /var/run/php \
    /var/log/nginx \
    /var/log/php \
    /var/log/presshost \
    /var/log/supervisor \
    /var/log/system

# Set proper ownership for directories
RUN chown -R www-data:www-data /var/run/php \
    && chown -R www-data:www-data /var/log/nginx /var/log/php /var/log/presshost \
    && chown -R www-data:www-data /site/uploads \
    && chown -R root:root /var/log/supervisor /var/log/system \
    && chmod 755 /site \
    && chmod 755 /site/uploads \
    && chmod 750 /var/run/php \
    && chmod 755 /var/log/nginx /var/log/php /var/log/presshost /var/log/supervisor /var/log/system

# Copy configuration files
COPY nginx/ /etc/nginx/
COPY php/ /etc/php/${PHP_VERSION}/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/ /usr/local/bin/
COPY logrotate.conf /etc/logrotate.conf
COPY logrotate.d/ /etc/logrotate.d/
COPY --chown=www-data:www-data app/ /site/press/

# Copy wp-config.php
COPY --chown=www-data:www-data wp-config.php /site/press/wp-config.php

COPY crontab /etc/cron.d/presshost
RUN chmod 0644 /etc/cron.d/presshost
RUN crontab /etc/cron.d/presshost

# Set executable permissions on scripts
RUN chmod +x /usr/local/bin/*.sh

# Create convenient aliases for download scripts
RUN ln -sf /usr/local/bin/download-wordpress.sh /usr/local/bin/download-wordpress && \
    ln -sf /usr/local/bin/download-classicpress.sh /usr/local/bin/download-classicpress

# Logrotate
RUN chmod 644 /etc/logrotate.conf
RUN chmod 644 /etc/logrotate.d/

# Update supervisord configuration to use correct PHP version
RUN sed -i "s/%(ENV_PHP_VERSION)s/${PHP_VERSION}/g" /etc/supervisor/conf.d/supervisord.conf

# Create PHP-FPM socket directory with proper permissions
RUN mkdir -p /var/run/php \
    && chown www-data:www-data /var/run/php \
    && chmod 755 /var/run/php

# Expose ports (TCP for HTTP/HTTPS and UDP for QUIC/HTTP3)
EXPOSE 80 443 443/udp

# Define volumes
# IMPORTANTE: /site/press e /site/uploads devem ser montados separadamente
VOLUME ["/site/press", "/site/uploads", "/var/www/certbot", "/etc/letsencrypt", "/etc/ssl/certs", "/var/log"]

WORKDIR /site

# Set entrypoint and command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]