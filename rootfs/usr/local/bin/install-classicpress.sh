#!/bin/bash
set -e

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SCRIPT_NAME="INSTALL-CLASSICPRESS"

source "${SCRIPT_DIR}/common-utils.sh"

TEMP_DIR="/tmp/classicpress-download"
PRESS_NAME="ClassicPress"

if [[ -n "${INSTALL_CLASSICPRESS_VERSION:-}" ]]; then
    DOWNLOAD_URL="https://github.com/ClassicPress/ClassicPress-release/archive/refs/tags/${INSTALL_CLASSICPRESS_VERSION}.zip"
    VERSION_INFO="ClassicPress ${INSTALL_CLASSICPRESS_VERSION}"
else
    DOWNLOAD_URL="https://www.classicpress.net/latest.zip"
    VERSION_INFO="ClassicPress (latest)"
fi

find_extracted_dir() {
    local temp_dir="$1"
    local extracted_dir
    
    extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d \( -name 'classicpress*' -o -name 'ClassicPress*' -o -name 'wordpress' \) 2>/dev/null | head -1)
    
    if [[ -z "$extracted_dir" ]] || [[ "$extracted_dir" == "$temp_dir" ]]; then
        extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d ! -name "$(basename "$temp_dir")" 2>/dev/null | head -1)
    fi
    
    if [[ -n "$extracted_dir" ]] && [[ "$extracted_dir" != "$temp_dir" ]] && [[ -d "$extracted_dir" ]]; then
        echo "$extracted_dir"
        return 0
    else
        return 1
    fi
}

download_classicpress() {
    info "Downloading ${VERSION_INFO}..."
    
    if safe_execute "rm -rf '$TEMP_DIR' && mkdir -p '$TEMP_DIR'" "Creating temporary directory"; then
        debug "Temporary directory created at: $TEMP_DIR"
    else
        error "Failed to create temporary directory"
        exit 1
    fi
    
    local archive_file="$TEMP_DIR/classicpress.zip"
    
    if ! download_press_archive "$DOWNLOAD_URL" "$archive_file" "$PRESS_NAME"; then
        exit 1
    fi
    
    if ! extract_press_archive "$archive_file" "$TEMP_DIR" "$PRESS_NAME"; then
        exit 1
    fi
    
    local extracted_dir
    if ! extracted_dir=$(find_extracted_dir "$TEMP_DIR"); then
        error "Could not find extracted ClassicPress directory"
        exit 1
    fi
    
    if [[ "$extracted_dir" != "$TEMP_DIR/classicpress" ]]; then
        mv "$extracted_dir" "$TEMP_DIR/classicpress"
        debug "Renamed extracted directory to: $TEMP_DIR/classicpress"
    fi
}

main() {
    download_classicpress
    
    if ! install_press_files "$TEMP_DIR/classicpress" "$PRESS_NAME"; then
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
        error "ClassicPress installation failed verification"
        exit 1
    fi
}

main "$@"
