<?php
if (!defined('ABSPATH')) {
	define('ABSPATH', __DIR__ . '/');
}

if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
	$_SERVER['HTTPS'] = 'on';
}

if (!function_exists('getenv_docker')) {
	// https://github.com/docker-library/wordpress/issues/588 (WP-CLI will load this file 2x)
	function getenv_docker($env, $default = 0, $filter = null) {
		$value = null;
		
		if ($fileEnv = getenv($env . '_FILE')) {
			$value = rtrim(file_get_contents($fileEnv), "\r\n");
		}
		else if (($val = getenv($env)) !== false) {
			$value = $val;
		}
		else if(isset($_ENV[$env])) {
			$value = $_ENV[$env];
		} else {
			return $default;
		}

		
		// Apply filter if specified
		if ($filter !== null && $value !== null) {
			$filtered = filter_var($value, $filter);
			return $filtered;
		}
		
		return $value;
	}
}

// Define WP_CLI before using it
defined('WP_CLI') || define('WP_CLI', defined('WP_CLI') && WP_CLI);
if (WP_CLI) {
	$_SERVER['HTTP_HOST'] = parse_url(getenv_docker('WP_SITEURL'), PHP_URL_HOST);
}

// Environment
define('WP_ENVIRONMENT_TYPE', getenv_docker('WP_ENVIRONMENT_TYPE', 'production'));
define('UPLOADS', '/site/uploads');

// Database
define('DB_NAME', getenv_docker('DB_NAME',''));
define('DB_USER', getenv_docker('DB_USER',''));
define('DB_PASSWORD', getenv_docker('DB_PASSWORD',''));
define('DB_HOST', getenv_docker('DB_HOST',''));
define('DB_CHARSET', getenv_docker('DB_CHARSET','utf8'));
define('DB_COLLATE', getenv_docker('DB_COLLATE','utf8mb4_unicode_ci'));

// Keys
define('AUTH_KEY', getenv_docker('AUTH_KEY',''));
define('SECURE_AUTH_KEY', getenv_docker('SECURE_AUTH_KEY',''));
define('LOGGED_IN_KEY', getenv_docker('LOGGED_IN_KEY',''));
define('NONCE_KEY', getenv_docker('NONCE_KEY',''));
define('AUTH_SALT', getenv_docker('AUTH_SALT',''));
define('SECURE_AUTH_SALT', getenv_docker('SECURE_AUTH_SALT',''));
define('LOGGED_IN_SALT', getenv_docker('LOGGED_IN_SALT',''));
define('NONCE_SALT', getenv_docker('NONCE_SALT',''));

// Debug
error_reporting(0);
ini_set('display_errors', 0);
define('WP_DEBUG', getenv_docker('WP_DEBUG', false, FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_LOG', getenv_docker('WP_DEBUG_LOG', false, FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_DISPLAY', getenv_docker('WP_DEBUG_DISPLAY', false, FILTER_VALIDATE_BOOLEAN));
define('SAVEQUERIES', getenv_docker('SAVEQUERIES', false, FILTER_VALIDATE_BOOLEAN));

// More
define('WP_SITEURL', getenv_docker('WP_SITEURL',''));
define('WP_HOME', getenv_docker('WP_HOME',''));
define('AUTOMATIC_UPDATER_DISABLED', getenv_docker('AUTOMATIC_UPDATER_DISABLED', true, FILTER_VALIDATE_BOOLEAN));
define('DISABLE_WP_CRON', getenv_docker('DISABLE_WP_CRON', true, FILTER_VALIDATE_BOOLEAN));
define('DISALLOW_FILE_EDIT', getenv_docker('DISALLOW_FILE_EDIT', true, FILTER_VALIDATE_BOOLEAN));
define('DISALLOW_FILE_MODS', getenv_docker('DISALLOW_FILE_MODS', true, FILTER_VALIDATE_BOOLEAN));
define('WPLANG', getenv_docker('WPLANG',''));
define('FS_METHOD', getenv_docker('FS_METHOD','direct'));
define('FORCE_SSL_ADMIN', getenv_docker('FORCE_SSL_ADMIN', true, FILTER_VALIDATE_BOOLEAN));
define('FORCE_SSL_LOGIN', getenv_docker('FORCE_SSL_LOGIN', true, FILTER_VALIDATE_BOOLEAN));
define('AUTOSAVE_INTERVAL', getenv_docker('AUTOSAVE_INTERVAL', 120, FILTER_VALIDATE_INT));
define('WP_POST_REVISIONS', getenv_docker('WP_POST_REVISIONS', -1, FILTER_VALIDATE_INT));
define('WP_AUTO_UPDATE_CORE', getenv_docker('WP_AUTO_UPDATE_CORE', false, FILTER_VALIDATE_BOOLEAN));
define('WP_MEMORY_LIMIT', getenv_docker('WP_MEMORY_LIMIT','512M'));
define('WP_MAX_MEMORY_LIMIT', getenv_docker('WP_MAX_MEMORY_LIMIT','512M'));
define('WP_CACHE', getenv_docker('WP_CACHE', true, FILTER_VALIDATE_BOOLEAN));
define('WP_CACHE_KEY_SALT', getenv_docker('WP_CACHE_KEY_SALT',''));
define('MEDIA_TRASH', getenv_docker('MEDIA_TRASH', true, FILTER_VALIDATE_BOOLEAN));
define('DISABLE_NAG_NOTICES', getenv_docker('DISABLE_NAG_NOTICES', true, FILTER_VALIDATE_BOOLEAN));

$table_prefix = 'wp_';

require_once ABSPATH . 'wp-settings.php';
