location /nginx-status {
    if ($presshost_admin_ip = 0) {
        return 403;
    }
    stub_status on;
}

location ~ ^/(fpm-status|fpm-ping)$ {
    if ($presshost_admin_ip = 0) {
        return 403;
    }

    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME "";
    fastcgi_param SCRIPT_NAME     $fastcgi_script_name;
    fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
}
