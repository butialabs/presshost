fastcgi_cache_path ${CACHE_PATH}/nginx levels=1:2 keys_zone=PRESSHOST:100m max_size=${NGINX_CACHE_MAX_SIZE} inactive=${NGINX_CACHE_INACTIVE} use_temp_path=off;
fastcgi_cache_key "$scheme$request_method$host$request_uri${NGINX_CACHE_KEY_MOBILE_SUFFIX}$is_logged_in";
