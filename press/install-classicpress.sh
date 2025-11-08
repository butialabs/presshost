#!/bin/bash
set -e

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="DOWNLOAD-CLASSICPRESS"

# Source common utilities
source "${SCRIPT_DIR}/common-utils.sh"

# Constants
WP_DIR="/site/press"
WP_CLI="/usr/local/bin/wp"
DOWNLOAD_URL="https://api.classicpress.net/latest/classicpress-latest.tar.gz"
TEMP_DIR="/tmp/classicpress-download"

# Function to check if ClassicPress/WordPress is already installed
check_existing_installation() {
    info "Checking for existing installation..."
    
    if [[ -f "${WP_DIR}/wp-config.php" ]] || [[ -f "${WP_DIR}/wp-load.php" ]]; then
        warning "WordPress/ClassicPress files already exist in ${WP_DIR}"
        
        # Ask for confirmation
        read -p "Do you want to overwrite the existing installation? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            info "Installation cancelled by user"
            exit 0
        fi
        
        warning "Backing up existing installation..."
        local backup_file="/tmp/classicpress-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        
        if safe_execute "tar -czf '$backup_file' -C '$WP_DIR' ." "Creating backup"; then
            success "Backup created at: $backup_file"
        else
            error "Failed to create backup"
            exit 1
        fi
    else
        success "No existing installation found"
    fi
}

# Function to download ClassicPress
download_classicpress() {
    info "Downloading latest ClassicPress..."
    
    # Create temporary directory
    if safe_execute "rm -rf '$TEMP_DIR' && mkdir -p '$TEMP_DIR'" "Creating temporary directory"; then
        debug "Temporary directory created at: $TEMP_DIR"
    else
        error "Failed to create temporary directory"
        exit 1
    fi
    
    # Download ClassicPress
    if safe_execute "curl -fsSL '$DOWNLOAD_URL' -o '$TEMP_DIR/classicpress.tar.gz'" "Downloading ClassicPress"; then
        success "ClassicPress downloaded successfully"
    else
        error "Failed to download ClassicPress"
        exit 1
    fi
    
    # Extract ClassicPress
    info "Extracting ClassicPress files..."
    if safe_execute "tar -xzf '$TEMP_DIR/classicpress.tar.gz' -C '$TEMP_DIR'" "Extracting archive"; then
        success "ClassicPress extracted successfully"
    else
        error "Failed to extract ClassicPress"
        exit 1
    fi
}

# Function to install ClassicPress files
install_classicpress() {
    info "Installing ClassicPress files..."
    
    # Create app directory if it doesn't exist
    if safe_execute "mkdir -p '$WP_DIR'" "Creating ClassicPress directory"; then
        debug "ClassicPress directory ready: $WP_DIR"
    else
        error "Failed to create ClassicPress directory"
        exit 1
    fi
    
    # Copy ClassicPress files (the extracted folder is named 'classicpress', excluding wp-config.php)
    info "Copying ClassicPress files (wp-config.php will be preserved from image)..."
    if safe_execute "rsync -av --exclude='wp-config.php' $TEMP_DIR/classicpress/ '$WP_DIR/'" "Copying ClassicPress files"; then
        success "ClassicPress files copied successfully"
    else
        # Fallback to cp if rsync is not available
        if safe_execute "cp -rf $TEMP_DIR/classicpress/* '$WP_DIR/'" "Copying ClassicPress files (fallback)"; then
            success "ClassicPress files copied successfully"
            
            # Remove wp-config-sample.php to avoid confusion
            if [[ -f "${WP_DIR}/wp-config-sample.php" ]]; then
                rm -f "${WP_DIR}/wp-config-sample.php"
                info "Removed wp-config-sample.php (using image's wp-config.php instead)"
            fi
        else
            error "Failed to copy ClassicPress files"
            exit 1
        fi
    fi
    
    # Set proper permissions
    info "Setting file permissions..."
    if safe_execute "chown -R www-data:www-data '$WP_DIR'" "Setting ownership"; then
        debug "Ownership set to www-data:www-data"
    else
        warning "Failed to set ownership"
    fi
    
    if safe_execute "find '$WP_DIR' -type d -exec chmod 755 {} \;" "Setting directory permissions"; then
        debug "Directory permissions set to 755"
    else
        warning "Failed to set directory permissions"
    fi
    
    if safe_execute "find '$WP_DIR' -type f -exec chmod 644 {} \;" "Setting file permissions"; then
        debug "File permissions set to 644"
    else
        warning "Failed to set file permissions"
    fi
    
    success "File permissions configured"
}

# Function to setup wp-content structure
setup_wp_content() {
    info "Setting up wp-content structure..."
    
    local dirs=(
        "uploads"
        "plugins"
        "themes"
        "upgrade"
        "cache"
    )
    
    for dir in "${dirs[@]}"; do
        local full_path="${WP_DIR}/wp-content/${dir}"
        if [[ ! -d "$full_path" ]]; then
            if safe_execute "mkdir -p '$full_path'" "Creating $dir directory"; then
                debug "Created: $full_path"
                
                if safe_execute "chown www-data:www-data '$full_path'" "Setting ownership for $dir"; then
                    debug "Ownership set for: $full_path"
                else
                    warning "Failed to set ownership for: $full_path"
                fi
            else
                warning "Failed to create: $full_path"
            fi
        fi
    done
    
    success "wp-content structure configured"
}

# Function to cleanup
cleanup() {
    info "Cleaning up temporary files..."
    
    if safe_execute "rm -rf '$TEMP_DIR'" "Removing temporary directory"; then
        debug "Temporary files removed"
    else
        warning "Failed to remove temporary files"
    fi
}

# Function to verify installation
verify_installation() {
    info "Verifying ClassicPress installation..."
    
    local required_files=(
        "wp-load.php"
        "wp-settings.php"
        "wp-blog-header.php"
        "index.php"
    )
    
    local missing_files=0
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "${WP_DIR}/${file}" ]]; then
            error "Missing required file: $file"
            missing_files=$((missing_files + 1))
        fi
    done
    
    if [[ $missing_files -eq 0 ]]; then
        success "All required ClassicPress files are present"
        
        # Get ClassicPress version
        local cp_version
        if command_exists wp; then
            cp_version=$(wp core version --allow-root --path="$WP_DIR" 2>/dev/null || echo "unknown")
            success "ClassicPress version: $cp_version"
        fi
        
        return 0
    else
        error "ClassicPress installation is incomplete ($missing_files files missing)"
        return 1
    fi
}

# Function to display next steps
show_next_steps() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              ClassicPress Installation Complete                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "IMPORTANT: wp-config.php is provided by the Docker image and should"
    echo "          NOT be edited. All configurations are made via environment"
    echo "          variables in the .env file"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Make sure your .env file is configured with:"
    echo "   - Database credentials (DB_NAME, DB_USER, DB_PASSWORD, DB_HOST)"
    echo "   - Site URLs (WP_SITEURL, WP_HOME)"
    echo "   - Security keys (AUTH_KEY, SECURE_AUTH_KEY, etc.)"
    echo ""
    echo "2. Verify volume structure:"
    echo "   - /site/press      → ClassicPress files"
    echo "   - /site/uploads  → Media uploads (separate volume)"
    echo ""
    echo "3. Install ClassicPress using WP-CLI:"
    echo "   wp core install \\"
    echo "     --url=\"https://yourdomain.com\" \\"
    echo "     --title=\"Your Site Title\" \\"
    echo "     --admin_user=\"admin\" \\"
    echo "     --admin_password=\"secure_password\" \\"
    echo "     --admin_email=\"admin@yourdomain.com\" \\"
    echo "     --allow-root"
    echo ""
    echo "4. Or access your site in a browser and follow the installation wizard:"
    echo "   https://yourdomain.com/wp-admin/install.php"
    echo ""
    echo "ClassicPress files location: ${WP_DIR}"
    echo "Uploads location: /site/uploads"
    echo ""
    echo "Note: ClassicPress is 100% compatible with WordPress plugins and themes,"
    echo "      so you can use WP-CLI commands normally."
    echo ""
}

# Main function
main() {
    log_script_start "Download ClassicPress"
    
    check_existing_installation
    download_classicpress
    install_classicpress
    setup_wp_content
    cleanup
    
    if verify_installation; then
        show_next_steps
        log_script_end 0 "Download ClassicPress"
        exit 0
    else
        error "ClassicPress installation failed verification"
        log_script_end 1 "Download ClassicPress"
        exit 1
    fi
}

# Execute main function
main "$@"