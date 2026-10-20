location ~ ^/purge(/.*)$ {
    if ($presshost_admin_ip = 0) {
        return 403;
    }

    fastcgi_cache_purge PRESSHOST "$real_scheme$request_method$http_host$1$is_logged_in";
}
