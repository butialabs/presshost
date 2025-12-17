[www]
user = ${APP_USER}
group = ${APP_GROUP}

listen = /run/php/php-fpm.sock
listen.owner = ${APP_USER}
listen.group = ${APP_GROUP}
listen.mode = 0660

clear_env = ${PHP_CLEAR_ENV}

pm = ${PHP_PM}
pm.max_children = ${PHP_PM_MAX_CHILDREN}
pm.start_servers = ${PHP_PM_START_SERVERS}
pm.min_spare_servers = ${PHP_PM_MIN_SPARE_SERVERS}
pm.max_spare_servers = ${PHP_PM_MAX_SPARE_SERVERS}
pm.max_requests = ${PHP_PM_MAX_REQUESTS}
pm.status_path = /fpm-status

ping.path = /fpm-ping
ping.response = pong

request_terminate_timeout = ${PHP_MAX_EXECUTION_TIME}

catch_workers_output = yes
decorate_workers_output = no

php_admin_flag[log_errors] = on
php_admin_value[error_log] = ${LOGS_PATH}/php-error.log
slowlog = ${LOGS_PATH}/php-slow.log
request_slowlog_timeout = 10s
