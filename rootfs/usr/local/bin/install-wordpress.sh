#!/bin/bash
set -e

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SCRIPT_NAME="INSTALL-WORDPRESS"

source "${SCRIPT_DIR}/common-utils.sh"

TEMP_DIR="/tmp/wordpress-download"
PRESS_NAME="WordPress"

if [[ -n "${INSTALL_WORDPRESS_VERSION:-}" ]]; then
    DOWNLOAD_URL="https://wordpress.org/wordpress-${INSTALL_WORDPRESS_VERSION}.zip"
    VERSION_INFO="WordPress ${INSTALL_WORDPRESS_VERSION}"
else
    DOWNLOAD_URL="https://wordpress.org/latest.zip"
    VERSION_INFO="WordPress (latest)"
fi

download_wordpress() {
    info "Downloading ${VERSION_INFO}..."
    
    if safe_execute "rm -rf '$TEMP_DIR' && mkdir -p '$TEMP_DIR'" "Creating temporary directory"; then
        debug "Temporary directory created at: $TEMP_DIR"
    else
        error "Failed to create temporary directory"
        exit 1
    fi
    
    local archive_file="$TEMP_DIR/wordpress.zip"
    
    if ! download_press_archive "$DOWNLOAD_URL" "$archive_file" "$PRESS_NAME"; then
        exit 1
    fi
    
    if ! extract_press_archive "$archive_file" "$TEMP_DIR" "$PRESS_NAME"; then
        exit 1
    fi
}

main() {
    download_wordpress
    
    if ! install_press_files "$TEMP_DIR/wordpress" "$PRESS_NAME"; then
        exit 1
    fi
    
    setup_press_content
    cleanup_temp_dir "$TEMP_DIR"
    
    if verify_press_installation "$PRESS_NAME"; then
        local wp_installed="false"
        if run_press_install "$PRESS_NAME"; then
            wp_installed="true"
        fi
        show_press_next_steps "$PRESS_NAME" "$wp_installed"
        exit 0
    else
        error "WordPress installation failed verification"
        exit 1
    fi
}

main "$@"
