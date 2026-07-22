geo $origin_local {
    default 0;
    127.0.0.0/8 1;
    10.0.0.0/8 1;
    172.16.0.0/12 1;
    192.168.0.0/16 1;
    ::1/128 1;
    fc00::/7 1;
}

map $http_x_origin_auth $origin_auth_ok {
    default 0;
    "${NGINX_ORIGIN_AUTH_SECRET}" 1;
}

map "$origin_local$origin_auth_ok" $origin_allow {
    default 1;
    00 0;
}
