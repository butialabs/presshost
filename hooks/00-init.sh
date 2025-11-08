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

# Configuration variables for Cloudflare
CLOUDFLARE_CONF_TPL="/nginx/cloudflare.conf.tpl"
CLOUDFLARE_CONF="/etc/nginx/conf.d/cloudflare.conf"

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

# Cloudflare IP configuration
info "Configuring Cloudflare real IP settings..."

## Check if template exists
if ! file_readable "$CLOUDFLARE_CONF_TPL"; then
    critical "Template $CLOUDFLARE_CONF_TPL not found or not readable"
    exit 1
fi

## Fetch Cloudflare IPv4 ranges
info "Fetching Cloudflare IPv4 ranges..."
local ipv4_ranges
if ipv4_ranges=$(curl -s -f https://www.cloudflare.com/ips-v4); then
    success "IPv4 ranges fetched successfully"
    debug "IPv4 ranges: $ipv4_ranges"
else
    error "Failed to fetch Cloudflare IPv4 ranges"
    exit 1
fi

## Fetch Cloudflare IPv6 ranges
info "Fetching Cloudflare IPv6 ranges..."
local ipv6_ranges
if ipv6_ranges=$(curl -s -f https://www.cloudflare.com/ips-v6); then
    success "IPv6 ranges fetched successfully"
    debug "IPv6 ranges: $ipv6_ranges"
else
    error "Failed to fetch Cloudflare IPv6 ranges"
    exit 1
fi

## Create temporary files for formatted IP ranges
local temp_ipv4=$(mktemp)
local temp_ipv6=$(mktemp)

## Format IPv4 ranges as nginx directives
while IFS= read -r ip; do
    if [[ -n "$ip" ]]; then
        echo "set_real_ip_from ${ip};" >> "$temp_ipv4"
    fi
done <<< "$ipv4_ranges"

## Format IPv6 ranges as nginx directives
while IFS= read -r ip; do
    if [[ -n "$ip" ]]; then
        echo "set_real_ip_from ${ip};" >> "$temp_ipv6"
    fi
done <<< "$ipv6_ranges"

## Create the final configuration by replacing placeholders
local temp_config=$(mktemp)

## Read template and replace placeholders line by line
while IFS= read -r line; do
    case "$line" in
        "{{IPV4}}")
            cat "$temp_ipv4"
            ;;
        "{{IPV6}}")
            cat "$temp_ipv6"
            ;;
        *)
            echo "$line"
            ;;
    esac
done < "$CLOUDFLARE_CONF_TPL" > "$temp_config"

## Move the configuration to its final location
if safe_execute "mv '$temp_config' '$CLOUDFLARE_CONF'" "Installing Cloudflare configuration"; then
    success "Cloudflare configuration created at $CLOUDFLARE_CONF"
    
    # Show summary of configured IPs
    local ipv4_count=$(echo -n "$ipv4_ranges" | grep -c '^')
    local ipv6_count=$(echo -n "$ipv6_ranges" | grep -c '^')
    info "Configured $ipv4_count IPv4 ranges and $ipv6_count IPv6 ranges"
else
    error "Failed to create Cloudflare configuration"
    exit 1
fi

## Clean up temporary files
rm -f "$temp_ipv4" "$temp_ipv6" "$temp_config"

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