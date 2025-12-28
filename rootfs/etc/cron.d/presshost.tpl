SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Press Cron (WP-Cli)
* * * * * root /usr/local/bin/wp --path="${APP_PATH}" --allow-root cron event run --due-now >> ${LOGS_PATH}/cron-presshost.log 2>&1

# NGINX (For renewed SSL certificates)
0 0 * * * root /usr/sbin/nginx -s reload >> ${LOGS_PATH}/cron-nginx.log 2>&1
