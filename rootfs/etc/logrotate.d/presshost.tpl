${LOGS_PATH}/*.log {
    size ${LOG_MAX_SIZE}
    rotate ${LOG_MAX_AGE}
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    dateext
    dateformat -%Y%m%d
    create 640 ${APP_USER} ${APP_GROUP}
}
