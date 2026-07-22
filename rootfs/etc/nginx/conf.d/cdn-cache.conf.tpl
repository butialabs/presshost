map $http_authorization $cdn_has_auth {
    default 0;
    ~. 1;
}

map $http_x_wp_nonce $cdn_has_nonce {
    default 0;
    ~. 1;
}

map "$skip_cache:$cdn_has_auth:$cdn_has_nonce" $cdn_bypass {
    default 0;
    ~*1 1;
}

map $cdn_bypass $cdn_browser_cache {
    0 "public, max-age=${NGINX_CDN_BROWSER_TTL}";
    1 "no-cache, no-store, must-revalidate, private";
}

map $cdn_bypass $cdn_edge_cache {
    0 "public, max-age=${NGINX_CDN_EDGE_TTL}, stale-while-revalidate=${NGINX_CDN_SWR}, stale-if-error=${NGINX_CDN_STALE_IF_ERROR}";
    1 "no-store";
}
