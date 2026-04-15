#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LOG_FILE="${LOGS_PATH}/cron-presshost.log"
source "${SCRIPT_DIR}/common-utils.sh" || { echo "ERROR: Failed to load common utilities" >&2; exit 1; }

info "Running WordPress cron events" >> "${LOG_FILE}" 2>&1

if /usr/local/bin/wp --path="${APP_PATH}" --allow-root cron event run --due-now >> "${LOG_FILE}" 2>&1; then
    success "WordPress cron events completed successfully" >> "${LOG_FILE}" 2>&1
else
    error "Failed to run WordPress cron events" >> "${LOG_FILE}" 2>&1
    exit 1
fi

exit 0