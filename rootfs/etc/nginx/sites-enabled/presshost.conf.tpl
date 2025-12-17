server {
    listen 80 default_server reuseport;
    listen [::]:80 default_server reuseport;
    listen 443 ssl default_server reuseport;
    listen [::]:443 ssl default_server reuseport;

    http2 on;
    server_name _;

    set $base /site;
    root $base/press;

    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_PRIVATE_PATH};

    include conf.d/security.conf;

    access_log ${LOGS_PATH}/nginx-access.log detailed buffer=256k flush=5s;
    error_log ${LOGS_PATH}/nginx-error.log warn;

    index index.php;

    limit_req zone=general_limit burst=20 nodelay;
    limit_conn conn_limit 10;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    include conf.d/compression.conf;
    include conf.d/static.conf;
    include conf.d/press.conf;
    include conf.d/proxy.conf;
    include conf.d/cache-purge.conf;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        include conf.d/fastcgi.conf;
        include conf.d/cache-fastcgi.conf;
    }

    include conf.d/status.conf;
}
