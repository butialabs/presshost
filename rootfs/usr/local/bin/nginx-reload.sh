#!/bin/bash
set -euo pipefail

SCRIPT_NAME="NGINX-RELOAD"
LOG_FILE="${LOGS_PATH:-/site/logs}/cron-nginx.log"
STATE_FILE="/run/nginx-reload.hash"
LOG_LEVEL=INFO
source "/usr/local/bin/common-utils.sh"

WATCH_FILES=(
    "${SSL_CERT_PATH:-/site/ssl/server.crt}"
    "${SSL_PRIVATE_PATH:-/site/ssl/server.key}"
    "${SSL_TRUSTED_CERT_PATH:-/site/ssl/server.crt}"
)

current_hash=$(
    for f in "${WATCH_FILES[@]}"; do
        [[ -f "$f" ]] && sha256sum "$f"
    done | sha256sum | awk '{print $1}'
)

previous_hash=""
[[ -f "$STATE_FILE" ]] && previous_hash=$(<"$STATE_FILE")

if [[ "$current_hash" == "$previous_hash" ]]; then
    exit 0
fi

if [[ -z "$previous_hash" ]]; then
    printf '%s' "$current_hash" > "$STATE_FILE"
    exit 0
fi

info "NGINX reload started" >> "${LOG_FILE}" 2>&1
info "SSL certificate change detected; reloading NGINX" >> "${LOG_FILE}" 2>&1
s6-svc -h /run/service/nginx >> "${LOG_FILE}" 2>&1
printf '%s' "$current_hash" > "$STATE_FILE"
success "NGINX reload finished" >> "${LOG_FILE}" 2>&1
