#!/bin/bash

# Common Utilities Script - Standardized logging and error handling
# This script provides reusable functions for consistent logging across all scripts
# Usage: source /path/to/common-utils.sh

# Prevent multiple sourcing
if [[ "${COMMON_UTILS_LOADED:-}" == "true" ]]; then
    return 0
fi
COMMON_UTILS_LOADED="true"

# Color definitions for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Default script name (can be overridden by sourcing script)
SCRIPT_NAME="${SCRIPT_NAME:-$(basename "${BASH_SOURCE[1]}" .sh | tr '[:lower:]' '[:upper:]')}"

# Log file configuration (can be overridden by sourcing script)
LOG_FILE="${LOG_FILE:-}"

# Enable/disable colored output (can be overridden by environment variable)
ENABLE_COLORS="${ENABLE_COLORS:-true}"

# Enable/disable file logging (disabled by default - always output to stdout/stderr)
ENABLE_FILE_LOGGING="${ENABLE_FILE_LOGGING:-false}"

# Internal function to get timestamp
_get_timestamp() {
    date +'%Y-%m-%d %H:%M:%S'
}

# Internal function to format log message
_format_message() {
    local level="$1"
    local message="$2"
    local color="$3"
    
    local timestamp
    timestamp="$(_get_timestamp)"
    
    if [[ "$ENABLE_COLORS" == "true" ]]; then
        echo -e "${color}[${timestamp}] ${SCRIPT_NAME} ${level}:${NC} ${message}"
    else
        echo "[${timestamp}] ${SCRIPT_NAME} ${level}: ${message}"
    fi
}

# Internal function to write to log file (disabled - output only to stdout/stderr)
_write_to_log() {
    # Function disabled - all output goes to stdout/stderr
    return 0
}

# Standard logging functions

# General log function (INFO level with green color)
log() {
    local message="$1"
    _format_message "INFO" "$message" "$GREEN"
    _write_to_log "INFO" "$message"
}

# Error logging function (ERROR level with red color, outputs to stderr)
error() {
    local message="$1"
    _format_message "ERROR" "$message" "$RED" >&2
    _write_to_log "ERROR" "$message"
}

# Warning logging function (WARNING level with yellow color)
warning() {
    local message="$1"
    _format_message "WARNING" "$message" "$YELLOW"
    _write_to_log "WARNING" "$message"
}

# Info logging function (INFO level with blue color)
info() {
    local message="$1"
    _format_message "INFO" "$message" "$BLUE"
    _write_to_log "INFO" "$message"
}

# Debug logging function (DEBUG level with purple color)
debug() {
    local message="$1"
    # Only show debug messages if DEBUG is enabled
    if [[ "${DEBUG:-false}" == "true" ]]; then
        _format_message "DEBUG" "$message" "$PURPLE"
        _write_to_log "DEBUG" "$message"
    fi
}

# Success logging function (SUCCESS level with cyan color)
success() {
    local message="$1"
    _format_message "SUCCESS" "$message" "$CYAN"
    _write_to_log "SUCCESS" "$message"
}

# Critical error function (CRITICAL level with white on red background)
critical() {
    local message="$1"
    if [[ "$ENABLE_COLORS" == "true" ]]; then
        echo -e "\033[41m\033[1;37m[$(date +'%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME} CRITICAL: ${message}${NC}" >&2
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME} CRITICAL: ${message}" >&2
    fi
    _write_to_log "CRITICAL" "$message"
}

# Utility functions for common operations

# Function to check if a command exists
command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

# Function to check if a file exists and is readable
file_readable() {
    local file="$1"
    [[ -f "$file" && -r "$file" ]]
}

# Function to check if a directory exists and is writable
dir_writable() {
    local dir="$1"
    [[ -d "$dir" && -w "$dir" ]]
}


# Function to safely execute a command with logging
safe_execute() {
    local cmd="$1"
    local description="${2:-Executing command}"
    
    debug "$description: $cmd"
    
    if eval "$cmd" 2>/dev/null; then
        debug "$description completed successfully"
        return 0
    else
        local exit_code=$?
        error "$description failed with exit code: $exit_code"
        return $exit_code
    fi
}

# Function to validate required environment variables
require_env_vars() {
    local missing_vars=()
    
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        critical "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
}

# Function to log script start
log_script_start() {
    local script_description="${1:-Script}"
    log "=== $script_description starting ==="
    log "Script: ${BASH_SOURCE[1]}"
    log "PID: $$"
    log "User: $(whoami)"
    log "Working directory: $(pwd)"
}

# Function to log script end
log_script_end() {
    local exit_code="${1:-0}"
    local script_description="${2:-Script}"
    
    if [[ $exit_code -eq 0 ]]; then
        success "=== $script_description completed successfully ==="
    else
        error "=== $script_description failed with exit code: $exit_code ==="
    fi
}

# Export functions so they can be used by sourcing scripts
export -f log error warning info debug success critical
export -f command_exists file_readable dir_writable safe_execute
export -f require_env_vars
export -f log_script_start log_script_end

# Log that common utilities have been loaded
debug "Common utilities loaded successfully"