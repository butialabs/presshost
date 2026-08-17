#!/bin/bash
set -euo pipefail

if [[ -z "${PRESS_CRON_LOCKED:-}" ]]; then
    export PRESS_CRON_LOCKED=1
    _log_dir="${LOGS_PATH:-/site/logs}"
    mkdir -p "$_log_dir" 2>/dev/null || true
    flock -n -E 99 /run/press-cron.lock "$0" "$@" && _rc=0 || _rc=$?
    if [[ $_rc -eq 99 ]]; then
        echo "[WARN] $(date -Iseconds) - previous run still in progress; skipping" \
            >> "${_log_dir}/cron-presshost.log" 2>/dev/null || true
        exit 0
    fi
    exit $_rc
fi

SCRIPT_NAME="PRESS-CRON"
APP_USER="${APP_USER:-www-data}"
APP_PATH="${APP_PATH:-/site/press}"
LOG_FILE="${LOGS_PATH:-/site/logs}/cron-presshost.log"
LOG_LEVEL=INFO
mkdir -p "$(dirname "${LOG_FILE}")" 2>/dev/null || true
source "/usr/local/bin/common-utils.sh"

info "Cron started" >> "${LOG_FILE}" 2>&1

if [[ ! -f "${APP_PATH}/wp-load.php" ]]; then
    info "No Press installation detected at ${APP_PATH}!" >> "${LOG_FILE}" 2>&1
    exit 0
fi

info "Running Press cron events" >> "${LOG_FILE}" 2>&1
if runuser -u "${APP_USER}" -- /usr/local/bin/wp --path="${APP_PATH}" cron event run --due-now >> "${LOG_FILE}" 2>&1; then
    success "Press cron events completed successfully" >> "${LOG_FILE}" 2>&1
else
    error "Failed to run Press cron events" >> "${LOG_FILE}" 2>&1
    exit 1
fi
