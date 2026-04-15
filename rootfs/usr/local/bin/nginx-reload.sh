#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LOG_FILE="${LOGS_PATH}/cron-nginx.log"
source "${SCRIPT_DIR}/common-utils.sh" || { echo "ERROR: Failed to load common utilities" >&2; exit 1; }

info "Reloading NGINX configuration" >> "${LOG_FILE}" 2>&1

# Using s6-svc
if s6-svc -h /run/service/nginx; then
    success "NGINX configuration reloaded successfully using s6-svc" >> "${LOG_FILE}" 2>&1
    exit 0
fi

# Using s6-rc
if s6-rc -d change nginx; then
    success "NGINX configuration reloaded successfully using s6-rc" >> "${LOG_FILE}" 2>&1
    exit 0
fi

# fallback
if /usr/sbin/nginx -s reload >> "${LOG_FILE}" 2>&1; then
    success "NGINX configuration reloaded successfully using nginx -s reload" >> "${LOG_FILE}" 2>&1
    exit 0
else
    error "Failed to reload NGINX configuration" >> "${LOG_FILE}" 2>&1
    exit 1
fi