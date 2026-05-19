${LOGS_PATH}/*.log {
    size ${LOG_MAX_SIZE}
    rotate ${LOG_MAX_AGE}
    missingok
    notifempty
    compress
    delaycompress
    dateext
    dateformat -%Y%m%d
    create 640 ${APP_USER} ${APP_GROUP}
    sharedscripts
    postrotate
        /bin/kill -SIGUSR1 $(cat /run/nginx.pid 2>/dev/null) 2>/dev/null || true
        /bin/kill -SIGUSR1 $(cat /run/php/php${PHP_VERSION}-fpm.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
