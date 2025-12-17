[www]
user = ${APP_USER}
group = ${APP_GROUP}

listen = /run/php/php-fpm.sock
listen.owner = ${APP_USER}
listen.group = ${APP_GROUP}
listen.mode = 0660
listen.backlog = ${PHP_FPM_LISTEN_BACKLOG}

clear_env = ${PHP_CLEAR_ENV}

pm = ${PHP_PM}
pm.max_children = ${PHP_PM_MAX_CHILDREN}
pm.start_servers = ${PHP_PM_START_SERVERS}
pm.min_spare_servers = ${PHP_PM_MIN_SPARE_SERVERS}
pm.max_spare_servers = ${PHP_PM_MAX_SPARE_SERVERS}
pm.max_requests = ${PHP_PM_MAX_REQUESTS}
pm.process_idle_timeout = ${PHP_PM_PROCESS_IDLE_TIMEOUT}
pm.status_path = /fpm-status

ping.path = /fpm-ping
ping.response = pong

rlimit_files = ${PHP_FPM_RLIMIT_FILES}
request_terminate_timeout = ${PHP_FPM_REQUEST_TERMINATE_TIMEOUT}

catch_workers_output = yes
decorate_workers_output = no

php_admin_flag[log_errors] = on
php_admin_value[error_log] = ${LOGS_PATH}/php-error.log
slowlog = ${LOGS_PATH}/php-slow.log
request_slowlog_timeout = 10s
