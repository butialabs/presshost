# Cloudflare

## Real IP Restoration from Cloudflare
### IPv4: https://www.cloudflare.com/ips-v4
{{IPV4}}
### IPv6: https://www.cloudflare.com/ips-v6
{{IPV6}}
### Use CF-Connecting-IP header for real client IP
real_ip_header CF-Connecting-IP;
real_ip_recursive on;

## Allow Cloudflare challenge pages
location /_cf_chl_opt/ {
    return 200;
}
