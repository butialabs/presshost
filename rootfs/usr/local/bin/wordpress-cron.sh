#!/bin/bash
set -euo pipefail

SCRIPT_NAME="WORDPRESS-CRON"
APP_USER="${APP_USER:-www-data}"
APP_PATH="${APP_PATH:-/site/press}"
LOG_FILE="${LOGS_PATH:-/site/logs}/cron-presshost.log"
source "/usr/local/bin/common-utils.sh"

if [[ ! -f "${APP_PATH}/wp-load.php" ]]; then
    info "No Press installation detected at ${APP_PATH}!" >> "${LOG_FILE}" 2>&1
    exit 0
fi

info "Running WordPress cron events as ${APP_USER}" >> "${LOG_FILE}" 2>&1

if runuser -u "${APP_USER}" -- /usr/local/bin/wp --path="${APP_PATH}" cron event run --due-now >> "${LOG_FILE}" 2>&1; then
    success "WordPress cron events completed successfully" >> "${LOG_FILE}" 2>&1
else
    error "Failed to run WordPress cron events" >> "${LOG_FILE}" 2>&1
    exit 1
fi
