#!/usr/bin/env bash
# PressHost initialization hook
# Executed on container start by shinsenter/php

# Enable strict error handling
set -e

# Use debug mode if enabled
! is-true "$DEBUG" || set -ex

# Source common utilities for logging
SCRIPT_NAME="PRESSHOST-INIT"
source /press/common-utils.sh || {
    echo "ERROR: Failed to load common utilities"
    exit 1
}

log_script_start "PressHost initialization"

# Create log directory if it doesn't exist
if [ ! -d "/var/log/presshost" ]; then
    echo "  Creating log directory..."
    mkdir -p /var/log/presshost
fi

# Initialize cache symlink if WordPress is installed
if [ -d "/site/press/wp-content" ]; then
    if [ ! -L "/site/press/wp-content/cache" ]; then
        echo "→ Creating cache symlink..."
        
        # If cache directory exists (not a symlink), backup it
        if [ -d "/site/press/wp-content/cache" ]; then
            echo "  Backing up existing cache directory..."
            mv "/site/press/wp-content/cache" "/site/press/wp-content/cache.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Create symlink
        ln -sf /site/cache /site/press/wp-content/cache
        echo "✓ Cache symlink created"
    else
        echo "✓ Cache symlink already exists"
    fi
fi

# Initialize uploads symlink if WordPress is installed
if [ -d "/site/press/wp-content" ]; then
    if [ ! -L "/site/press/wp-content/uploads" ]; then
        echo "→ Creating uploads symlink..."
        
        # If uploads directory exists (not a symlink), backup it
        if [ -d "/site/press/wp-content/uploads" ]; then
            echo "  Backing up existing uploads directory..."
            mv "/site/press/wp-content/uploads" "/site/press/wp-content/uploads.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Create symlink
        ln -sf /site/uploads /site/press/wp-content/uploads
        echo "✓ Uploads symlink created"
    else
        echo "✓ Uploads symlink already exists"
    fi
fi

# Fix permissions
if ! is-true "$DISABLE_CHOWN_FIX"; then
    echo "→ Fixing permissions..."
    web-chown fix /var/log/presshost /site/uploads /site/cache
fi

# CDN Configuration
if [ -n "$USE_CDN" ]; then
    info "USE_CDN environment variable detected: $USE_CDN"
    
    case "$USE_CDN" in
        cloudflare)
            info "Running Cloudflare configuration..."
            if /press/configure-cloudflare.sh; then
                success "Cloudflare configuration completed"
            else
                error "Cloudflare configuration failed"
                exit 1
            fi
            ;;
        *)
            warning "Unsupported USE_CDN value: $USE_CDN (currently only 'cloudflare' is supported)"
            ;;
    esac
else
    info "USE_CDN not set, skipping CDN configuration"
fi

# Auto-install WordPress or ClassicPress if INSTALL_PRESS is set
if [ -n "$INSTALL_PRESS" ]; then
    info "INSTALL_PRESS environment variable detected: $INSTALL_PRESS"
    
    # Check if installation already exists
    if [ -f "/site/press/wp-load.php" ]; then
        warning "WordPress/ClassicPress already installed, skipping auto-install"
    else
        case "$INSTALL_PRESS" in
            wordpress)
                info "Running WordPress auto-installation..."
                if /usr/local/bin/install-wordpress.sh; then
                    success "WordPress auto-installation completed"
                else
                    error "WordPress auto-installation failed"
                fi
                ;;
            classicpress)
                info "Running ClassicPress auto-installation..."
                if /usr/local/bin/install-classicpress.sh; then
                    success "ClassicPress auto-installation completed"
                else
                    error "ClassicPress auto-installation failed"
                fi
                ;;
            *)
                warning "Invalid INSTALL_PRESS value: $INSTALL_PRESS (expected 'wordpress' or 'classicpress')"
                ;;
        esac
    fi
fi

success "PressHost initialization completed"

# Log initialization success in debug mode
if is-true "$DEBUG"; then
    debug "PressHost initialized with APP_PATH=$APP_PATH"
    debug "Permissions fixed for uploads, cache, and logs"
    debug "User: $(whoami) (UID=$(id -u))"
fi

# Show WP-CLI version if greeting is not disabled
if ! is-true "$DISABLE_GREETING"; then
    command -v wp >/dev/null 2>&1 && wp --version --allow-root || true
fi

log_script_end 0 "PressHost initialization"