#!/bin/bash

if [[ "${COMMON_UTILS_LOADED:-}" == "true" ]]; then
    return 0
fi
COMMON_UTILS_LOADED="true"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

SCRIPT_NAME="${SCRIPT_NAME:-$(basename "${BASH_SOURCE[1]}" .sh | tr '[:lower:]' '[:upper:]')}"

_get_timestamp() {
    date +'%Y-%m-%d %H:%M:%S'
}

_format_message() {
    local level="$1"
    local message="$2"
    local color="$3"
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME} ${level}:${NC} ${message}"
}

log() {
    _format_message "INFO" "$1" "$GREEN"
}

error() {
    _format_message "ERROR" "$1" "$RED" >&2
}

warning() {
    _format_message "WARNING" "$1" "$YELLOW"
}

info() {
    _format_message "INFO" "$1" "$BLUE"
}

debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        _format_message "DEBUG" "$1" "$PURPLE"
    fi
}

success() {
    _format_message "SUCCESS" "$1" "$CYAN"
}

critical() {
    echo -e "\033[41m\033[1;37m[$(date +'%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME} CRITICAL: ${1}${NC}" >&2
}

verbose() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        _format_message "VERBOSE" "$1" "$WHITE"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

file_readable() {
    [[ -f "$1" && -r "$1" ]]
}

dir_writable() {
    [[ -d "$1" && -w "$1" ]]
}

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

export -f log error warning info debug success critical verbose
export -f command_exists file_readable dir_writable safe_execute require_env_vars

WHIPTAIL_BACKTITLE="${WHIPTAIL_BACKTITLE:-PressHost}"
WHIPTAIL_DEFAULT_HEIGHT=20
WHIPTAIL_DEFAULT_WIDTH=70
TERM_HEIGHT=24
TERM_WIDTH=80
CALC_HEIGHT=20
CALC_WIDTH=70

_whiptail_has_tty() {
    [[ -r /dev/tty && -w /dev/tty ]]
}

_whiptail_msgbox() {
    local title="$1"
    local backtitle="$2"
    local message="$3"
    local height="$4"
    local width="$5"

    local text
    text="$(printf '%b' "$message")"

    if command_exists whiptail && _whiptail_has_tty; then
        if whiptail --title "$title" --backtitle "$backtitle" --msgbox "$text" "$height" "$width" \
            </dev/tty >/dev/tty; then
            return 0
        fi

        printf '%b\n' "${title}: ${text}" >&2
        return 0
    fi

    printf '%b\n' "${title}: ${text}" >&2
    return 0
}

_whiptail_textbox_file() {
    local title="$1"
    local backtitle="$2"
    local file="$3"
    local height="$4"
    local width="$5"

    if command_exists whiptail && _whiptail_has_tty; then
        if whiptail --title "$title" --backtitle "$backtitle" --textbox "$file" "$height" "$width" \
            </dev/tty >/dev/tty; then
            return 0
        fi

        printf '%s\n' "${title}: could not render textbox; showing raw content below" >&2
    fi

    if [[ -r "$file" ]]; then
        cat "$file" >&2
    else
        printf '%s\n' "${title}: file not readable: ${file}" >&2
    fi
    return 0
}

get_terminal_size() {
    local term_lines term_cols
    term_lines=$(tput lines 2>/dev/null || echo 24)
    term_cols=$(tput cols 2>/dev/null || echo 80)
    
    TERM_HEIGHT=$((term_lines > 24 ? term_lines : 24))
    TERM_WIDTH=$((term_cols > 80 ? term_cols : 80))
}

calc_dialog_size() {
    local requested_height="${1:-$WHIPTAIL_DEFAULT_HEIGHT}"
    local requested_width="${2:-$WHIPTAIL_DEFAULT_WIDTH}"
    
    get_terminal_size
    
    local max_height=$((TERM_HEIGHT - 4))
    local max_width=$((TERM_WIDTH - 4))
    
    CALC_HEIGHT=$((requested_height < max_height ? requested_height : max_height))
    CALC_WIDTH=$((requested_width < max_width ? requested_width : max_width))
    
    [[ $CALC_HEIGHT -lt 8 ]] && CALC_HEIGHT=8
    [[ $CALC_WIDTH -lt 50 ]] && CALC_WIDTH=50
}

show_whiptail_error() {
    local message="$1"
    local title="${2:-Error}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 10 60
    _whiptail_msgbox "$title" "$backtitle" "$message" "$CALC_HEIGHT" "$CALC_WIDTH"
}

show_whiptail_warning() {
    local message="$1"
    local title="${2:-Warning}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 10 60
    _whiptail_msgbox "$title" "$backtitle" "⚠ ${message}" "$CALC_HEIGHT" "$CALC_WIDTH"
}

show_whiptail_info() {
    local message="$1"
    local title="${2:-Information}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 12 60
    _whiptail_msgbox "$title" "$backtitle" "$message" "$CALC_HEIGHT" "$CALC_WIDTH"
}

show_whiptail_success() {
    local message="$1"
    local title="${2:-Success}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 12 60
    _whiptail_msgbox "$title" "$backtitle" "✓ ${message}" "$CALC_HEIGHT" "$CALC_WIDTH"
}

show_whiptail_textbox() {
    local file="$1"
    local title="${2:-Details}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 22 78
    _whiptail_textbox_file "$title" "$backtitle" "$file" "$CALC_HEIGHT" "$CALC_WIDTH"
}

update_whiptail_progress() {
    local percent="$1"
    local message="$2"
    local progress_pipe="${3:-${PRESSHOST_PROGRESS_PIPE:-}}"
    local progress_fd="${PRESSHOST_PROGRESS_FD:-}"
    local gauge_pid="${PRESSHOST_GAUGE_PID:-}"

    if [[ -n "$gauge_pid" ]] && [[ "$gauge_pid" =~ ^[0-9]+$ ]]; then
        if ! kill -0 "$gauge_pid" 2>/dev/null; then
            return 0
        fi
    fi

    if [[ -n "$progress_fd" ]] && [[ "$progress_fd" =~ ^[0-9]+$ ]]; then
        local text
        text="$(printf '%b' "$message")"
        {
            printf 'XXX\n'
            printf '%s\n' "$percent"
            printf '%s\n' "$text"
            printf 'XXX\n'
        } >&${progress_fd} 2>/dev/null || true
        return 0
    fi
    
    if [[ -n "$progress_pipe" ]] && [[ -p "$progress_pipe" ]]; then
        local text
        text="$(printf '%b' "$message")"
        {
            printf 'XXX\n'
            printf '%s\n' "$percent"
            printf '%s\n' "$text"
            printf 'XXX\n'
        } >"$progress_pipe" 2>/dev/null || true
    fi
}

validate_email() {
    local email="$1"
    local regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    [[ "$email" =~ $regex ]]
}

validate_url() {
    local url="$1"
    local regex="^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}.*$"
    [[ "$url" =~ $regex ]]
}

validate_username() {
    local username="$1"
    local regex="^[a-zA-Z0-9_]{3,20}$"
    [[ "$username" =~ $regex ]]
}

validate_version() {
    local version="$1"
    local regex="^[0-9]+\.[0-9]+(\.[0-9]+)?$"
    [[ "$version" =~ $regex ]]
}

validate_locale() {
    local locale="$1"
    local regex="^[a-z]{2}_[A-Z]{2}$"
    [[ "$locale" =~ $regex ]]
}

export -f get_terminal_size calc_dialog_size
export -f show_whiptail_error show_whiptail_warning show_whiptail_info show_whiptail_success
export -f show_whiptail_textbox
export -f update_whiptail_progress
export -f validate_email validate_url validate_username validate_version validate_locale

PRESS_WP_DIR="${APP_PATH:-/site/press}"
PRESS_UPLOADS_DIR="${UPLOADS_PATH:-/site/uploads}"
PRESS_CACHE_DIR="${CACHE_PATH:-/site/cache}"
PRESS_LOGS_DIR="${LOGS_PATH:-/site/logs}"
PRESS_USER="${APP_USER:-www-data}"
PRESS_GROUP="${APP_GROUP:-www-data}"
readonly PRESS_WP_CLI="/usr/local/bin/wp"
readonly PRESS_DEFAULT_TITLE="PressHost"
readonly PRESS_DEFAULT_USER="presshost"
readonly PRESS_DEFAULT_SKIP_EMAIL="true"
readonly PRESS_DEFAULT_LOCALE="en_US"

generate_password() {
    local length="${1:-16}"
    tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom | head -c "$length" 2>/dev/null || \
    openssl rand -base64 "$length" 2>/dev/null | head -c "$length" || \
    date +%s%N | sha256sum | head -c "$length"
}

download_press_archive() {
    local download_url="$1"
    local archive_file="$2"
    local press_name="${3:-Press}"
    local max_attempts=3
    local attempt=1
    local download_success=false
    
    info "Downloading from: $download_url"
    while [[ $attempt -le $max_attempts ]]; do
        info "Download attempt $attempt of $max_attempts..."
        if curl -fsSL "$download_url" -o "$archive_file"; then
            success "${press_name} downloaded successfully"
            download_success=true
            break
        else
            warning "Download attempt $attempt failed"
            if [[ $attempt -lt $max_attempts ]]; then
                sleep 3
            fi
            attempt=$((attempt + 1))
        fi
    done
    
    if [[ "$download_success" != "true" ]]; then
        error "Failed to download ${press_name} after $max_attempts attempts"
        return 1
    fi
    
    if [[ ! -f "$archive_file" ]] || [[ ! -s "$archive_file" ]]; then
        error "Downloaded file is missing or empty"
        return 1
    fi
    
    info "Downloaded file size: $(du -h "$archive_file" | cut -f1)"
    return 0
}

extract_press_archive() {
    local archive_file="$1"
    local dest_dir="$2"
    local press_name="${3:-Press}"
    
    info "Extracting ${press_name} files..."
    if command_exists unzip; then
        if unzip -q "$archive_file" -d "$dest_dir"; then
            success "${press_name} extracted successfully"
            return 0
        else
            error "Failed to extract ${press_name}"
            return 1
        fi
    else
        error "unzip command not found"
        return 1
    fi
}

install_press_files() {
    local source_dir="$1"
    local press_name="${2:-Press}"
    
    info "Installing ${press_name} files..."
    
    if safe_execute "mkdir -p '$PRESS_WP_DIR'" "Creating ${press_name} directory"; then
        debug "${press_name} directory ready: $PRESS_WP_DIR"
    else
        error "Failed to create ${press_name} directory"
        return 1
    fi
    
    info "Copying ${press_name} files..."
    if safe_execute "cp -rf ${source_dir}/* '$PRESS_WP_DIR/'" "Copying ${press_name} files"; then
        success "${press_name} files copied successfully"
        if [[ -f "${PRESS_WP_DIR}/wp-config-sample.php" ]]; then
            rm -f "${PRESS_WP_DIR}/wp-config-sample.php"
        fi
    else
        error "Failed to copy ${press_name} files"
        return 1
    fi
    
    set_press_permissions
    return 0
}

set_press_permissions() {
    info "Setting file permissions..."
    safe_execute "fast-chown '$PRESS_WP_DIR'" "Setting ownership"
    safe_execute "find '$PRESS_WP_DIR' -type d -exec chmod 755 {} \;" "Setting directory permissions"
    safe_execute "find '$PRESS_WP_DIR' -type f -exec chmod 644 {} \;" "Setting file permissions"
    success "File permissions configured"
}

setup_press_content() {
    info "Setting up wp-content structure..."
    local dirs=("uploads" "plugins" "themes" "upgrade" "cache")
    for dir in "${dirs[@]}"; do
        local full_path="${PRESS_WP_DIR}/wp-content/${dir}"
        if [[ ! -d "$full_path" ]]; then
            if safe_execute "mkdir -p '$full_path'" "Creating $dir directory"; then
                safe_execute "fast-chown '$full_path'" "Setting ownership for $dir"
            fi
        fi
    done
    success "wp-content structure configured"
}

cleanup_temp_dir() {
    local temp_dir="$1"
    info "Cleaning up temporary files..."
    safe_execute "rm -rf '$temp_dir'" "Removing temporary directory"
}

PRESS_TYPE=""
PRESS_VERSION=""

verify_press_installation() {
    PRESS_TYPE=""
    PRESS_VERSION=""
    
    local required_files=("wp-load.php" "wp-settings.php" "wp-blog-header.php" "index.php")
    for file in "${required_files[@]}"; do
        if [[ ! -f "${PRESS_WP_DIR}/${file}" ]]; then
            return 1
        fi
    done
    
    local version_file="${PRESS_WP_DIR}/wp-includes/version.php"
    
    if [[ -f "$version_file" ]]; then
        if grep -q '\$cp_version\s*=' "$version_file" 2>/dev/null || \
           grep -q "classicpress_version" "$version_file" 2>/dev/null || \
           [[ -f "${PRESS_WP_DIR}/wp-includes/classicpress/class-classicpress.php" ]]; then
            PRESS_TYPE="ClassicPress"
            PRESS_VERSION=$(grep -oP "\\\$cp_version\s*=\s*['\"]?\K[0-9]+\.[0-9]+(\.[0-9]+)?" "$version_file" 2>/dev/null || echo "")
            if [[ -z "$PRESS_VERSION" ]]; then
                PRESS_VERSION=$(grep -oP "\\\$wp_version\s*=\s*['\"]?\K[0-9]+\.[0-9]+(\.[0-9]+)?" "$version_file" 2>/dev/null || echo "")
            fi
        else
            PRESS_TYPE="WordPress"
            PRESS_VERSION=$(grep -oP "\\\$wp_version\s*=\s*['\"]?\K[0-9]+\.[0-9]+(\.[0-9]+)?" "$version_file" 2>/dev/null || echo "")
        fi
    else
        if [[ -f "${PRESS_WP_DIR}/wp-includes/classicpress/class-classicpress.php" ]]; then
            PRESS_TYPE="ClassicPress"
        else
            PRESS_TYPE="WordPress"
        fi
    fi
    
    if [[ -z "$PRESS_VERSION" ]] && command_exists wp; then
        PRESS_VERSION=$(wp core version --allow-root --path="$PRESS_WP_DIR" 2>/dev/null || echo "")
    fi
    
    [[ -z "$PRESS_VERSION" ]] && PRESS_VERSION="unknown"
    return 0
}

check_press_installed() {
    $PRESS_WP_CLI core is-installed --allow-root --path="$PRESS_WP_DIR" 2>/dev/null
}

create_press_config() {
    local press_name="${1:-Press}"
    local source_config="/tmp/wp-config.php"
    
    info "Setting up wp-config.php for ${press_name}..."
    
    if [[ -f "${PRESS_WP_DIR}/wp-config.php" ]]; then
        info "wp-config.php already exists, skipping creation"
        return 0
    fi
    
    if [[ ! -f "$source_config" ]]; then
        error "Source wp-config.php not found at $source_config"
        return 1
    fi
    
    if safe_execute "cp '$source_config' '${PRESS_WP_DIR}/wp-config.php'" "Copying wp-config.php"; then
        success "wp-config.php copied successfully"
        safe_execute "fast-chown '${PRESS_WP_DIR}/wp-config.php'" "Setting wp-config.php ownership"
        safe_execute "chmod 640 '${PRESS_WP_DIR}/wp-config.php'" "Setting wp-config.php permissions"
        return 0
    else
        error "Failed to copy wp-config.php"
        return 1
    fi
}

generate_press_secrets() {
    local press_name="${1:-Press}"
    local secrets_file="${PRESS_WP_DIR}/wp-secrets.php"
    
    info "Checking ${press_name} salt keys configuration..."
    
    if [[ -z "${AUTH_KEY:-}" ]] && [[ -z "${SECURE_AUTH_KEY:-}" ]] && [[ -z "${LOGGED_IN_KEY:-}" ]] && \
       [[ -z "${NONCE_KEY:-}" ]] && [[ -z "${AUTH_SALT:-}" ]] && [[ -z "${SECURE_AUTH_SALT:-}" ]] && \
       [[ -z "${LOGGED_IN_SALT:-}" ]] && [[ -z "${NONCE_SALT:-}" ]]; then
        info "Generating wp-secrets.php with salt keys from WordPress API..."
        echo '<?php' > "$secrets_file"
        if curl -sf https://api.wordpress.org/secret-key/1.1/salt/ >> "$secrets_file"; then
            success "Salt keys generated successfully"
            safe_execute "fast-chown '$secrets_file'" "Setting wp-secrets.php ownership"
            safe_execute "chmod 640 '$secrets_file'" "Setting wp-secrets.php permissions"
            return 0
        else
            error "Failed to generate salt keys from WordPress API"
            rm -f "$secrets_file"
            return 1
        fi
    else
        info "Salt keys provided via environment variables"
        return 0
    fi
}

run_press_install() {
    local press_name="${1:-Press}"
    
    info "Running ${press_name} installation..."
    
    local site_url="${INSTALL_URL:-${WP_HOME:-${WP_SITEURL:-}}}"
    local site_title="${INSTALL_TITLE:-$PRESS_DEFAULT_TITLE}"
    local admin_user="${INSTALL_USER:-$PRESS_DEFAULT_USER}"
    local admin_pass="${INSTALL_PASS:-}"
    local admin_email="${INSTALL_EMAIL:-}"
    local skip_email="${INSTALL_SKIP_EMAIL:-$PRESS_DEFAULT_SKIP_EMAIL}"
    local locale="${INSTALL_LOCALE:-$PRESS_DEFAULT_LOCALE}"
    
    if [[ -z "$site_url" ]]; then
        warning "INSTALL_URL, WP_HOME, or WP_SITEURL must be set for automated installation"
        return 1
    fi
    
    if [[ -z "$admin_email" ]]; then
        warning "INSTALL_EMAIL must be set for automated installation"
        return 1
    fi
    
    local generated_pass=""
    if [[ -z "$admin_pass" ]]; then
        generated_pass=$(generate_password 16)
        admin_pass="$generated_pass"
    fi
    
    if check_press_installed; then
        warning "${press_name} is already installed in the database"
        return 0
    fi
    
    if ! create_press_config "$press_name"; then
        error "Failed to create wp-config.php"
        return 1
    fi
    
    generate_press_secrets "$press_name" || true
    
    info "Installing ${press_name}..."
    info "  URL: $site_url"
    info "  Title: $site_title"
    info "  Admin: $admin_user"
    
    local install_cmd="$PRESS_WP_CLI core install --allow-root --path='$PRESS_WP_DIR'"
    install_cmd="$install_cmd --url='$site_url' --title='$site_title'"
    install_cmd="$install_cmd --admin_user='$admin_user' --admin_password='$admin_pass'"
    install_cmd="$install_cmd --admin_email='$admin_email' --locale='$locale'"
    [[ "$skip_email" == "true" ]] && install_cmd="$install_cmd --skip-email"
    
    if eval "$install_cmd"; then
        success "${press_name} installed successfully!"
        if [[ -n "$generated_pass" ]]; then
            echo ""
            echo "  Admin Username: $admin_user"
            echo "  Admin Password: $generated_pass"
            echo "  Save this password now!"
            echo ""
        fi
        return 0
    else
        error "${press_name} installation failed"
        return 1
    fi
}

show_press_next_steps() {
    local press_name="${1:-Press}"
    local installed="${2:-false}"
    
    echo ""
    if [[ "$installed" == "true" ]]; then
        success "${press_name} installed successfully!"
        info "URL: ${INSTALL_URL:-${WP_HOME:-${WP_SITEURL:-'your-domain'}}}"
        info "Admin: ${INSTALL_URL:-${WP_HOME:-${WP_SITEURL:-'your-domain'}}}/wp-admin/"
    else
        warning "Installation incomplete. See: https://github.com/butialabs/presshost"
    fi
}

export -f generate_password download_press_archive extract_press_archive install_press_files
export -f set_press_permissions setup_press_content cleanup_temp_dir verify_press_installation
export -f check_press_installed create_press_config generate_press_secrets run_press_install show_press_next_steps

debug "Common utilities loaded successfully"
