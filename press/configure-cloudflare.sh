#!/usr/bin/env bash
# PressHost Cloudflare configuration script
# Configures Nginx to trust Cloudflare IP ranges

# Enable strict error handling
set -e

# Use debug mode if enabled
! is-true "$DEBUG" || set -ex

# Source common utilities for logging
SCRIPT_NAME="CLOUDFLARE-CONFIG"
source /press/common-utils.sh || {
    echo "ERROR: Failed to load common utilities"
    exit 1
}

# Configuration variables for Cloudflare
CLOUDFLARE_CONF_TPL="/nginx/cloudflare.conf.tpl"
CLOUDFLARE_CONF="/etc/nginx/conf.d/cloudflare.conf"

log_script_start "Cloudflare IP configuration"

# Check if template exists
if ! file_readable "$CLOUDFLARE_CONF_TPL"; then
    critical "Template $CLOUDFLARE_CONF_TPL not found or not readable"
    exit 1
fi

# Fetch Cloudflare IPv4 ranges
info "Fetching Cloudflare IPv4 ranges..."
local ipv4_ranges
if ipv4_ranges=$(curl -s -f https://www.cloudflare.com/ips-v4); then
    success "IPv4 ranges fetched successfully"
    debug "IPv4 ranges: $ipv4_ranges"
else
    error "Failed to fetch Cloudflare IPv4 ranges"
    exit 1
fi

# Fetch Cloudflare IPv6 ranges
info "Fetching Cloudflare IPv6 ranges..."
local ipv6_ranges
if ipv6_ranges=$(curl -s -f https://www.cloudflare.com/ips-v6); then
    success "IPv6 ranges fetched successfully"
    debug "IPv6 ranges: $ipv6_ranges"
else
    error "Failed to fetch Cloudflare IPv6 ranges"
    exit 1
fi

# Create temporary files for formatted IP ranges
local temp_ipv4=$(mktemp)
local temp_ipv6=$(mktemp)

# Format IPv4 ranges as nginx directives
while IFS= read -r ip; do
    if [[ -n "$ip" ]]; then
        echo "set_real_ip_from ${ip};" >> "$temp_ipv4"
    fi
done <<< "$ipv4_ranges"

# Format IPv6 ranges as nginx directives
while IFS= read -r ip; do
    if [[ -n "$ip" ]]; then
        echo "set_real_ip_from ${ip};" >> "$temp_ipv6"
    fi
done <<< "$ipv6_ranges"

# Create the final configuration by replacing placeholders
local temp_config=$(mktemp)

# Read template and replace placeholders line by line
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

# Move the configuration to its final location
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

# Clean up temporary files
rm -f "$temp_ipv4" "$temp_ipv6" "$temp_config"

log_script_end 0 "Cloudflare IP configuration"