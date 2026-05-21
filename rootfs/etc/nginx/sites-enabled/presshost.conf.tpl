server {
    ${NGINX_HTTP_LISTEN}
    listen ${NGINX_HTTPS_PORT} ssl default_server reuseport;
    listen [::]:${NGINX_HTTPS_PORT} ssl default_server reuseport;
    ${NGINX_HTTP3_LISTEN}

    http2 on;
    server_name ${NGINX_SERVER_NAME};

    set $base /site;
    root $base/press;

    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_PRIVATE_PATH};
    ssl_trusted_certificate ${SSL_TRUSTED_CERT_PATH};
    ssl_stapling ${NGINX_SSL_STAPLING};
    ssl_stapling_verify ${NGINX_SSL_STAPLING_VERIFY};
    ${NGINX_HTTP3_HEADER}

    set $loggable 1;

    include conf.d/headers.conf;
    include conf.d/block-exploits.conf;

    access_log ${LOGS_PATH}/nginx-access.log detailed buffer=256k flush=5s if=$loggable;
    error_log ${LOGS_PATH}/nginx-error.log ${NGINX_LOG_LEVEL};

    index index.php;

    location = /wp-login.php {
        limit_req zone=login_limit burst=10 nodelay;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        include conf.d/fastcgi.conf;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    include conf.d/compression.conf;
    include conf.d/static.conf;
    include conf.d/proxy.conf;
    include conf.d/cache-purge.conf;

    location ~ \.php$ {
        limit_req zone=global_limit burst=${NGINX_RATE_BURST} nodelay;
        limit_conn conn_limit ${NGINX_CONN_LIMIT};
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        include conf.d/fastcgi.conf;
        include conf.d/cache-fastcgi.conf;
    }

    include conf.d/status.conf;

    include conf.d/custom-presshost.conf;
}
