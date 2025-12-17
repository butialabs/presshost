<?php
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

if (!function_exists('getenv_docker')) {
    function getenv_docker($env, $default = 0, $filter = null) {
        $value = null;
        if ($fileEnv = getenv($env . '_FILE')) {
            $value = rtrim(file_get_contents($fileEnv), "\r\n");
        } else if (($val = getenv($env)) !== false) {
            $value = $val;
        } else if (isset($_ENV[$env])) {
            $value = $_ENV[$env];
        } else {
            return $default;
        }
        if ($filter !== null && $value !== null) {
            return filter_var($value, $filter);
        }
        return $value;
    }
}

defined('WP_CLI') || define('WP_CLI', defined('WP_CLI') && WP_CLI);
if (WP_CLI) {
    $_SERVER['HTTP_HOST'] = parse_url(getenv_docker('WP_SITEURL'), PHP_URL_HOST);
}

define('WP_ENVIRONMENT_TYPE', getenv_docker('WP_ENVIRONMENT_TYPE', 'production'));

define('DB_NAME', getenv_docker('DB_NAME', ''));
define('DB_USER', getenv_docker('DB_USER', ''));
define('DB_PASSWORD', getenv_docker('DB_PASSWORD', ''));
define('DB_HOST', getenv_docker('DB_HOST', ''));
define('DB_CHARSET', getenv_docker('DB_CHARSET', 'utf8mb4'));
define('DB_COLLATE', getenv_docker('DB_COLLATE', 'utf8mb4_unicode_ci'));

$required_vars = ['DB_NAME', 'DB_USER', 'DB_PASSWORD', 'DB_HOST'];
foreach ($required_vars as $var) {
    if (empty(constant($var))) {
        error_log("PressHost: Missing required environment variable: $var");
    }
}

define('WP_DEBUG', getenv_docker('WP_DEBUG', false, FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_LOG', getenv_docker('WP_DEBUG_LOG', false, FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_DISPLAY', getenv_docker('WP_DEBUG_DISPLAY', false, FILTER_VALIDATE_BOOLEAN));
define('SAVEQUERIES', getenv_docker('SAVEQUERIES', false, FILTER_VALIDATE_BOOLEAN));

define('WP_SITEURL', getenv_docker('WP_SITEURL', ''));
define('WP_HOME', getenv_docker('WP_HOME', ''));
define('AUTOMATIC_UPDATER_DISABLED', getenv_docker('AUTOMATIC_UPDATER_DISABLED', false, FILTER_VALIDATE_BOOLEAN));
define('DISABLE_WP_CRON', getenv_docker('DISABLE_WP_CRON', true, FILTER_VALIDATE_BOOLEAN));
define('DISALLOW_FILE_EDIT', getenv_docker('DISALLOW_FILE_EDIT', false, FILTER_VALIDATE_BOOLEAN));
define('DISALLOW_FILE_MODS', getenv_docker('DISALLOW_FILE_MODS', false, FILTER_VALIDATE_BOOLEAN));
define('WPLANG', getenv_docker('WPLANG', 'en_US'));
define('FS_METHOD', getenv_docker('FS_METHOD', 'direct'));
define('FORCE_SSL_ADMIN', getenv_docker('FORCE_SSL_ADMIN', true, FILTER_VALIDATE_BOOLEAN));
define('FORCE_SSL_LOGIN', getenv_docker('FORCE_SSL_LOGIN', true, FILTER_VALIDATE_BOOLEAN));
define('AUTOSAVE_INTERVAL', getenv_docker('AUTOSAVE_INTERVAL', 120, FILTER_VALIDATE_INT));
define('WP_POST_REVISIONS', getenv_docker('WP_POST_REVISIONS', -1, FILTER_VALIDATE_INT));
define('WP_MEMORY_LIMIT', getenv_docker('WP_MEMORY_LIMIT', '512M'));
define('WP_MAX_MEMORY_LIMIT', getenv_docker('WP_MAX_MEMORY_LIMIT', '512M'));
define('WP_CACHE', getenv_docker('WP_CACHE', false, FILTER_VALIDATE_BOOLEAN));
define('WP_CACHE_KEY_SALT', getenv_docker('WP_CACHE_KEY_SALT', ''));
define('MEDIA_TRASH', getenv_docker('MEDIA_TRASH', true, FILTER_VALIDATE_BOOLEAN));
define('DISABLE_NAG_NOTICES', getenv_docker('DISABLE_NAG_NOTICES', true, FILTER_VALIDATE_BOOLEAN));

define('SMTP_USER', getenv_docker('SMTP_USER', ''));
define('SMTP_PASS', getenv_docker('SMTP_PASS', ''));
define('SMTP_HOST', getenv_docker('SMTP_HOST', ''));
define('SMTP_FROM', getenv_docker('SMTP_FROM', ''));
define('SMTP_NAME', getenv_docker('SMTP_NAME', ''));
define('SMTP_PORT', getenv_docker('SMTP_PORT', ''));
define('SMTP_SECURE', getenv_docker('SMTP_SECURE', ''));
define('SMTP_AUTH', getenv_docker('SMTP_AUTH', true, FILTER_VALIDATE_BOOLEAN));
define('SMTP_DEBUG', getenv_docker('SMTP_DEBUG', false, FILTER_VALIDATE_BOOLEAN));

if (file_exists(ABSPATH . 'wp-secrets.php')) {
    require_once ABSPATH . 'wp-secrets.php';
} else {
    define('AUTH_KEY', getenv_docker('AUTH_KEY', ''));
    define('SECURE_AUTH_KEY', getenv_docker('SECURE_AUTH_KEY', ''));
    define('LOGGED_IN_KEY', getenv_docker('LOGGED_IN_KEY', ''));
    define('NONCE_KEY', getenv_docker('NONCE_KEY', ''));
    define('AUTH_SALT', getenv_docker('AUTH_SALT', ''));
    define('SECURE_AUTH_SALT', getenv_docker('SECURE_AUTH_SALT', ''));
    define('LOGGED_IN_SALT', getenv_docker('LOGGED_IN_SALT', ''));
    define('NONCE_SALT', getenv_docker('NONCE_SALT', ''));
}

foreach (array_merge(getenv(), $_ENV) as $key => $value) {
    if (strpos($key, 'PRESS_') === 0 && $value !== false && $value !== '') {
        $constant_name = substr($key, 6);
        if (!defined($constant_name)) {
            $lower_value = strtolower($value);
            if ($lower_value === 'true' || $lower_value === 'false' || $lower_value === '1' || $lower_value === '0') {
                define($constant_name, getenv_docker($key, false, FILTER_VALIDATE_BOOLEAN));
            } elseif (is_numeric($value) && strpos($value, '.') === false) {
                define($constant_name, getenv_docker($key, 0, FILTER_VALIDATE_INT));
            } else {
                define($constant_name, getenv_docker($key, ''));
            }
        }
    }
}

$table_prefix = 'wp_';

require_once ABSPATH . 'wp-settings.php';
