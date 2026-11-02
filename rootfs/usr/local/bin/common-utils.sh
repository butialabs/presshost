#!/bin/bash

if [[ "${COMMON_UTILS_LOADED:-}" == "true" ]]; then
    return 0
fi

COMMON_UTILS_LOADED="true"
declare -xr RED='\033[0;31m'
declare -xr GREEN='\033[0;32m'
declare -xr YELLOW='\033[1;33m'
declare -xr BLUE='\033[0;34m'
declare -xr PURPLE='\033[0;35m'
declare -xr CYAN='\033[0;36m'
declare -xr WHITE='\033[1;37m'
declare -xr NC='\033[0m'

SCRIPT_NAME="${SCRIPT_NAME:-$(basename "${BASH_SOURCE[1]}" .sh | tr '[:lower:]' '[:upper:]')}"

readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4
readonly LOG_LEVEL_TRACE=5

_resolve_log_level() {
    local raw="${LOG_LEVEL:-WARN}"
    case "${raw^^}" in
        ERROR|ERR|CRITICAL|CRIT|FATAL|0|1) echo "$LOG_LEVEL_ERROR" ;;
        WARN|WARNING|2)                    echo "$LOG_LEVEL_WARN" ;;
        INFO|NOTICE|3)                     echo "$LOG_LEVEL_INFO" ;;
        DEBUG|4)                           echo "$LOG_LEVEL_DEBUG" ;;
        TRACE|VERBOSE|5)                   echo "$LOG_LEVEL_TRACE" ;;
        *)                                 echo "$LOG_LEVEL_WARN" ;;
    esac
}

_log_enabled() {
    local required="$1"
    local current
    current=$(_resolve_log_level)
    (( current >= required ))
}

_format_message() {
    local level="$1"
    local message="$2"
    local color="$3"
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME} ${level}:${NC} ${message}"
}

critical() {
    _log_enabled "$LOG_LEVEL_ERROR" || return 0
    echo -e "\033[41m\033[1;37m[$(date +'%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME} CRITICAL: ${1}${NC}" >&2
}

error() {
    _log_enabled "$LOG_LEVEL_ERROR" || return 0
    _format_message "ERROR" "$1" "$RED" >&2
}

warning() {
    _log_enabled "$LOG_LEVEL_WARN" || return 0
    _format_message "WARNING" "$1" "$YELLOW"
}

info() {
    _log_enabled "$LOG_LEVEL_INFO" || return 0
    _format_message "INFO" "$1" "$BLUE"
}

success() {
    _log_enabled "$LOG_LEVEL_INFO" || return 0
    _format_message "SUCCESS" "$1" "$CYAN"
}

debug() {
    _log_enabled "$LOG_LEVEL_DEBUG" || return 0
    _format_message "DEBUG" "$1" "$PURPLE"
}

trace() {
    _log_enabled "$LOG_LEVEL_TRACE" || return 0
    _format_message "TRACE" "$1" "$WHITE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

export -f error warning info debug success critical trace
export -f _resolve_log_level _log_enabled
export -f command_exists

derive_host_from_url() {
    local url="$1"
    url="${url#http://}"
    url="${url#https://}"
    url="${url%%/*}"
    url="${url%%\?*}"
    url="${url%%:*}"
    echo "$url"
}

derive_path_from_url() {
    local url="$1"
    url="${url#http://}"
    url="${url#https://}"
    url="${url%%\?*}"
    url="${url%%#*}"
    [[ "$url" == */* ]] || return 0
    url="/${url#*/}"
    echo "${url%/}"
}

export -f derive_host_from_url
export -f derive_path_from_url

PRESS_WP_DIR="${APP_PATH:-/site/press}"

generate_local_salts() {
    local target_file="$1"
    local keys=(AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT)
    {
        echo "<?php"
        local key value
        for key in "${keys[@]}"; do
            value=$(openssl rand -base64 64 | tr -d '\n\r' | head -c 64)
            value="${value//\'/}"
            printf "define('%s', '%s');\n" "$key" "$value"
        done
    } > "$target_file"
}
export -f generate_local_salts

press_is_classicpress() {
    local wp_dir="${1:-$PRESS_WP_DIR}"
    local version_file="${wp_dir}/wp-includes/version.php"

    if [[ -f "${wp_dir}/wp-includes/classicpress/class-classicpress.php" ]]; then
        return 0
    fi
    if [[ ! -f "$version_file" ]]; then
        return 1
    fi
    grep -qE '\$cp_version[[:space:]]*=|classicpress_version' "$version_file" 2>/dev/null
}

press_has_object_cache_dropin() {
    local wp_dir="${1:-$PRESS_WP_DIR}"
    [[ -f "${wp_dir}/wp-content/object-cache.php" ]]
}

export -f press_is_classicpress press_has_object_cache_dropin

debug "Common utilities loaded successfully"
