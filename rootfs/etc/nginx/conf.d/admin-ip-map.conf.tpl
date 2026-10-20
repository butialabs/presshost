geo $realip_remote_addr $presshost_admin_ip {
    default 0;
    127.0.0.0/8 1;
    ::1/128 1;
${NGINX_STATUS_ALLOW_BLOCK}
}
