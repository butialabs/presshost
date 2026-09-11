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

# auto | cli | http
PRESS_CRON_MODE="${PRESS_CRON_MODE:-auto}"

press_cron_request() {
    local url="$1"
    shift

    local -a args=(
        -sS -k
        -o /dev/null
        -w '%{http_code}'
        --connect-timeout "${PRESS_CRON_HTTP_CONNECT_TIMEOUT:-5}"
        --max-time "${PRESS_CRON_HTTP_TIMEOUT:-120}"
        -A 'PressHost-Cron'
        "$@"
    )

    local out=""
    out=$(curl "${args[@]}" "$url" 2>>"${LOG_FILE}") || true
    printf '%s' "${out:-000}"
}

run_press_cron_http() {
    local site_url host
    site_url="${WP_HOME:-${WP_SITEURL:-${SITEURL:-}}}"
    host=$(derive_host_from_url "$site_url")

    local https_port="${NGINX_HTTPS_PORT:-443}"
    local http_port="${NGINX_HTTP_PORT:-80}"
    local url code

    if [[ -n "$host" ]]; then
        url="https://${host}:${https_port}/wp-cron.php?doing_wp_cron"
        code=$(press_cron_request "$url" --resolve "${host}:${https_port}:127.0.0.1")
    else
        url="https://127.0.0.1:${https_port}/wp-cron.php?doing_wp_cron"
        code=$(press_cron_request "$url")
    fi

    if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
        info "Cron dispatched over HTTP to ${url} (HTTP ${code})" >> "${LOG_FILE}" 2>&1
        return 0
    fi
    warning "HTTP cron request to ${url} returned ${code}" >> "${LOG_FILE}" 2>&1

    if [[ -n "$host" ]]; then
        url="http://${host}:${http_port}/wp-cron.php?doing_wp_cron"
        code=$(press_cron_request "$url" -L \
            --resolve "${host}:${http_port}:127.0.0.1" \
            --resolve "${host}:${https_port}:127.0.0.1")
    else
        url="http://127.0.0.1:${http_port}/wp-cron.php?doing_wp_cron"
        code=$(press_cron_request "$url" -L)
    fi

    if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
        info "Cron dispatched over HTTP to ${url} (HTTP ${code})" >> "${LOG_FILE}" 2>&1
        return 0
    fi
    warning "HTTP cron request to ${url} returned ${code}" >> "${LOG_FILE}" 2>&1

    return 1
}

run_press_cron_cli() {
    info "Running Press cron events" >> "${LOG_FILE}" 2>&1
    if runuser -u "${APP_USER}" -- /usr/local/bin/wp --path="${APP_PATH}" cron event run --due-now >> "${LOG_FILE}" 2>&1; then
        success "Press cron events completed successfully" >> "${LOG_FILE}" 2>&1
        return 0
    fi
    error "Failed to run Press cron events" >> "${LOG_FILE}" 2>&1
    return 1
}

press_cron_needs_http() {
    press_is_classicpress "$APP_PATH" && press_has_object_cache_dropin "$APP_PATH"
}

info "Cron started" >> "${LOG_FILE}" 2>&1

if [[ ! -f "${APP_PATH}/wp-load.php" ]]; then
    info "No Press installation detected at ${APP_PATH}!" >> "${LOG_FILE}" 2>&1
    exit 0
fi

use_http=false
case "$PRESS_CRON_MODE" in
    http)
        use_http=true
        ;;
    cli)
        use_http=false
        ;;
    auto)
        if press_cron_needs_http; then
            use_http=true
        fi
        ;;
    *)
        warning "Unknown PRESS_CRON_MODE '${PRESS_CRON_MODE}'; falling back to auto" >> "${LOG_FILE}" 2>&1
        if press_cron_needs_http; then
            use_http=true
        fi
        ;;
esac

if [[ "$use_http" == "true" ]]; then
    info "Running Press cron events via HTTP (FPM)" >> "${LOG_FILE}" 2>&1
    if run_press_cron_http; then
        success "Press cron events via HTTP completed successfully" >> "${LOG_FILE}" 2>&1
        exit 0
    fi
    error "HTTP cron dispatch failed; falling back to WP-CLI" >> "${LOG_FILE}" 2>&1
fi

run_press_cron_cli
