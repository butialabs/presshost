load_module modules/ngx_http_brotli_filter_module.so;
load_module modules/ngx_http_brotli_static_module.so;
load_module modules/ngx_http_cache_purge_module.so;

user ${APP_USER};
worker_processes auto;
worker_rlimit_nofile 65535;
worker_priority -5;
pid /run/nginx.pid;
error_log ${LOGS_PATH}/nginx-error.log warn;

events {
    multi_accept on;
    use epoll;
    worker_connections 65535;
    accept_mutex off;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    charset utf-8;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    server_tokens off;
    log_not_found off;
    types_hash_max_size 2048;
    types_hash_bucket_size 64;
    server_names_hash_bucket_size 128;
    server_names_hash_max_size 4096;

    access_log off;
    error_log /dev/null;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:100m;
    ssl_session_tickets off;
    ssl_dhparam /etc/nginx/dhparam.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_stapling ${NGINX_SSL_STAPLING};
    ssl_stapling_verify ${NGINX_SSL_STAPLING_VERIFY};
    resolver 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 valid=60s;
    resolver_timeout 2s;

    keepalive_timeout ${NGINX_KEEPALIVE_TIMEOUT};
    keepalive_requests ${NGINX_KEEPALIVE_REQUESTS};
    client_body_timeout ${NGINX_CLIENT_BODY_TIMEOUT};
    client_header_timeout ${NGINX_CLIENT_HEADER_TIMEOUT};
    send_timeout ${NGINX_SEND_TIMEOUT};

    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE};
    client_body_buffer_size ${NGINX_CLIENT_BODY_BUFFER_SIZE};
    client_header_buffer_size ${NGINX_CLIENT_HEADER_BUFFER_SIZE};
    large_client_header_buffers ${NGINX_LARGE_CLIENT_HEADER_BUFFERS};
    output_buffers ${NGINX_OUTPUT_BUFFERS};

    fastcgi_connect_timeout ${NGINX_FASTCGI_CONNECT_TIMEOUT};
    fastcgi_send_timeout ${NGINX_FASTCGI_SEND_TIMEOUT};
    fastcgi_read_timeout ${NGINX_FASTCGI_READ_TIMEOUT};
    fastcgi_buffer_size ${NGINX_FASTCGI_BUFFER_SIZE};
    fastcgi_buffers ${NGINX_FASTCGI_BUFFERS};
    fastcgi_busy_buffers_size ${NGINX_FASTCGI_BUSY_BUFFERS_SIZE};

    variables_hash_max_size 2048;
    variables_hash_bucket_size 128;

    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=api_limit:50m rate=100r/s;
    limit_req_zone $binary_remote_addr zone=general_limit:50m rate=50r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

    log_format detailed '$remote_addr - $http_host [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent" '
                        'rt=$request_time uct="$upstream_connect_time" '
                        'uht="$upstream_header_time" urt="$upstream_response_time" '
                        'cache=$upstream_cache_status mobile=$is_mobile';

    map $http_user_agent $is_mobile {
        default 0;
        ~*android 1;
        ~*iphone 1;
        ~*ipad 1;
        ~*mobile 1;
        ~*webos 1;
        ~*opera.mini 1;
        ~*blackberry 1;
        ~*windows.phone 1;
    }

    map $http_cookie $is_logged_in {
        default 0;
        ~*wordpress_logged_in 1;
        ~*comment_author 1;
    }

    map $request_uri $skip_cache_uri {
        default 0;
        ~*/wp-admin 1;
        ~*/wp-login\.php 1;
        ~*/wp-cron\.php 1;
        ~*/xmlrpc\.php 1;
        ~*preview=true 1;
        ~*^/feed 1;
        ~*/sitemap.*\.xml 1;
        ~*/cart/ 1;
        ~*/checkout/ 1;
        ~*/my-account/ 1;
        ~*/fpm-status 1;
        ~*/fpm-ping 1;
        ~*/nginx_status 1;
    }

    map $http_cookie $skip_cache_cookie {
        default 0;
        ~*wordpress_logged_in 1;
        ~*comment_author 1;
        ~*wp-postpass 1;
        ~*woocommerce_items_in_cart 1;
        ~*woocommerce_cart_hash 1;
        ~*wordpress_no_cache 1;
    }

    map $request_method $skip_cache_method {
        default 0;
        POST 1;
    }

    map "$skip_cache_uri:$skip_cache_cookie:$skip_cache_method" $skip_cache {
        default 0;
        ~*1 1;
    }

    fastcgi_cache_path ${CACHE_PATH}/nginx/fastcgi levels=1:2 keys_zone=PRESSHOST:100m max_size=${NGINX_CACHE_MAX_SIZE} inactive=${NGINX_CACHE_INACTIVE} use_temp_path=off;
    fastcgi_cache_key "$scheme$request_method$host$request_uri$is_mobile$is_logged_in";

    include /etc/nginx/sites-enabled/*;
}
