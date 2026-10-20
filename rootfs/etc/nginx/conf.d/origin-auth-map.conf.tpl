geo $realip_remote_addr $origin_local {
    default 0;
    127.0.0.0/8 1;
    ::1/128 1;
${NGINX_ORIGIN_AUTH_ALLOW_BLOCK}
}

# Case-sensitive, anchored comparison.
map $http_x_origin_auth $origin_auth_ok {
    default 0;
    "~^${NGINX_ORIGIN_AUTH_SECRET_RE}$" 1;
}

map "$origin_local$origin_auth_ok" $origin_allow {
    default 1;
    00 0;
}
