${LOGS_PATH}/nginx-access.log ${LOGS_PATH}/nginx-error.log ${LOGS_PATH}/php-fpm.log ${LOGS_PATH}/php-slow.log ${LOGS_PATH}/cron-presshost.log ${LOGS_PATH}/cron-nginx.log ${LOGS_PATH}/safe-chown.log {
    daily
    maxsize ${LOG_MAX_SIZE}
    rotate ${LOG_MAX_AGE}
    missingok
    notifempty
    compress
    delaycompress
    dateext
    dateformat -%Y%m%d
    create 640 root ${APP_GROUP}
    sharedscripts
    postrotate
        s6-svc -1 /run/service/nginx 2>/dev/null || true
        s6-svc -1 /run/service/php-fpm 2>/dev/null || true
    endscript
}

${LOGS_PATH}/php-error.log ${LOGS_PATH}/wp-debug.log {
    daily
    maxsize ${LOG_MAX_SIZE}
    rotate ${LOG_MAX_AGE}
    missingok
    notifempty
    compress
    delaycompress
    dateext
    dateformat -%Y%m%d
    create 640 ${APP_USER} ${APP_GROUP}
}
