fastcgi_cache_path ${CACHE_PATH}/nginx levels=1:2 keys_zone=PRESSHOST:${NGINX_CACHE_KEY_ZONE_SIZE} max_size=${NGINX_CACHE_MAX_SIZE} inactive=${NGINX_CACHE_INACTIVE} use_temp_path=off;
fastcgi_cache_key "$real_scheme$request_method$http_host$request_uri$is_logged_in";
