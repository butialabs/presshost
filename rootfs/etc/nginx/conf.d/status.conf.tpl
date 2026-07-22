location /nginx-status {
    stub_status on;
    allow 127.0.0.1;
    allow ::1;
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;
}

location ~ ^/(fpm-status|fpm-ping)$ {
    allow 127.0.0.1;
    allow ::1;
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;

    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME "";
    fastcgi_param SCRIPT_NAME     $fastcgi_script_name;
    fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
}
