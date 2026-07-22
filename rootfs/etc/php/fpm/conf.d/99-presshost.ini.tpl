max_execution_time = ${PHP_MAX_EXECUTION_TIME}
max_input_time = ${PHP_MAX_INPUT_TIME}
max_input_vars = ${PHP_MAX_INPUT_VARS}
memory_limit = ${PHP_MEMORY_LIMIT}
post_max_size = ${PHP_POST_MAX_SIZE}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}
default_socket_timeout = ${PHP_DEFAULT_SOCKET_TIMEOUT}
date.timezone = ${TZ}

expose_php = Off

output_buffering = ${PHP_OUTPUT_BUFFERING}

opcache.enable = ${PHP_OPCACHE_ENABLE}
opcache.memory_consumption = ${PHP_OPCACHE_MEMORY}
opcache.interned_strings_buffer = ${PHP_OPCACHE_INTERNED_STRINGS}
opcache.max_accelerated_files = ${PHP_OPCACHE_MAX_FILES}
opcache.revalidate_freq = ${PHP_OPCACHE_REVALIDATE_FREQ}
opcache.validate_timestamps = ${PHP_OPCACHE_VALIDATE_TIMESTAMPS}
opcache.save_comments = 1

opcache.jit = ${PHP_OPCACHE_JIT}
opcache.jit_buffer_size = ${PHP_OPCACHE_JIT_BUFFER_SIZE}

session.cookie_httponly = ${PHP_SESSION_COOKIE_HTTPONLY}
session.cookie_secure = ${PHP_SESSION_COOKIE_SECURE}
session.cookie_samesite = ${PHP_SESSION_COOKIE_SAMESITE}
session.use_strict_mode = ${PHP_SESSION_USE_STRICT_MODE}

apc.enabled = ${PHP_APCU_ENABLED}
apc.shm_size = ${PHP_APCU_SHM_SIZE}
apc.ttl = ${PHP_APCU_TTL}
apc.enable_cli = ${PHP_APCU_ENABLE_CLI}

realpath_cache_size = ${PHP_REALPATH_CACHE_SIZE}
realpath_cache_ttl = ${PHP_REALPATH_CACHE_TTL}

display_errors = Off
display_startup_errors = Off
log_errors = On
error_reporting = ${PHP_ERROR_REPORTING}

disable_functions = ${PHP_DISABLE_FUNCTIONS}
