fastcgi_hide_header Cache-Control;
fastcgi_hide_header Expires;
add_header Cache-Control $cdn_browser_cache;
add_header CDN-Cache-Control $cdn_edge_cache;
