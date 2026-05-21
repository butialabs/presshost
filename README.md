# PressHost 🚀

> Docker image for WordPress and ClassicPress hosting with NGINX and PHP 8.4.

[![Docker Image](https://img.shields.io/badge/docker-presshost-blue.svg)](https://github.com/butialabs/presshost)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PHP Version](https://img.shields.io/badge/php-8.4-purple.svg)](https://www.php.net/)
[![NGINX](https://img.shields.io/badge/nginx-1.26-brightgreen.svg)](https://nginx.org/)
[![s6-overlay](https://img.shields.io/badge/s6--overlay-3.2.2.0-orange.svg)](https://github.com/just-containers/s6-overlay)

## Features

https://github.com/user-attachments/assets/92308dad-0dd8-4b38-9f5e-f22cc136fb31

- ⚡ Based on Debian + NGINX 1.26 + PHP 8.4 + s6-overlay v3
- 🌱 Everything is done via environment variables; PHP configurations, NGINX, and even WordPress constants are handled by environment variables. No need to edit wp-config.php.
- 🧠 Real caching support, works well with WP Super Cache, W3 Total Cache, WP Fastest Cache, and also with NGINX FastCGI Cache (via NGINX Helper).
- 📦 Separate code, uploads, cache, and logs!
- 🔧 Interactive installer, start the container, run `docker exec -it presshost ./presshost` and perform the guided installation.

## 🚀

PressHost is already trusted by high-traffic websites, including:

- 🎫 [Catraca Livre](https://catracalivre.com.br) - cultural events and entertainment platform
- 📖 [Manual do Usuario](https://manualdousuario.net) - technology and tutorials website

Together, these sites handle **more than 20 million pageviews per month**, proving PressHost's reliability and performance at scale.

## Quick Start

```bash
wget https://raw.githubusercontent.com/butialabs/presshost/main/compose.yml
nano compose.yml
docker compose up -d
```

### Required variables

| Variable      | Description                                                          | Example                   |
| ------------- | -------------------------------------------------------------------- | ------------------------- |
| `DB_NAME`     | Database name                                                        | `presshost`               |
| `DB_USER`     | Database user                                                        | `presshost`               |
| `DB_PASSWORD` | Database password                                                    | `p@ssw0rd`                |
| `DB_HOST`     | Database host                                                        | `db`                      |
| `SITEURL`     | Site URL, used for `server_name` and as default for WP_SITEURL/WP_HOME | `https://your-domain.xyz` |

> `WP_SITEURL` and `WP_HOME` fall back to `SITEURL` when not set. `server_name` is also derived from the host portion of `SITEURL`.

### Volumes

| Path            | Description                              |
| --------------- | ---------------------------------------- |
| `/site/press`   | Press files                              |
| `/site/uploads` | Media files (wp-content/uploads)         |
| `/site/cache`   | Cache files (wp-content/cache) and NGINX |
| `/site/logs`    | Log files                                |

## Installation

> If it's a migration, you can skip the installation and just copy the files to the correct volumes.

> Upon startup, an index.php file would be displayed automatically if none already exists.

## All Environments

### Database

| Variable     | Default              | Description            |
| ------------ | -------------------- | ---------------------- |
| `DB_CHARSET` | `utf8mb4`            | Database character set |
| `DB_COLLATE` | `utf8mb4_unicode_ci` | Database collation     |

### Press

| Variable                     | Default      | Description                                         |
| ---------------------------- | ------------ | --------------------------------------------------- |
| `WP_ENVIRONMENT_TYPE`        | `production` | Environment type (production, staging, development) |
| `WP_DEBUG`                   | `false`      | Enable debug mode                                   |
| `WP_DEBUG_LOG`               | `false`      | Enable debug logging                                |
| `WP_DEBUG_DISPLAY`           | `false`      | Display debug messages                              |
| `SAVEQUERIES`                | `false`      | Save database queries for debugging                 |
| `AUTOMATIC_UPDATER_DISABLED` | `false`      | Disable automatic updates                           |
| `DISALLOW_FILE_EDIT`         | `false`      | Disable file editing in admin                       |
| `DISALLOW_FILE_MODS`         | `false`      | Disable file modifications in admin                 |
| `WPLANG`                     | `en_US`      | Language setting                                    |
| `FS_METHOD`                  | `direct`     | Filesystem method                                   |
| `FORCE_SSL_ADMIN`            | `true`       | Force SSL for admin                                 |
| `FORCE_SSL_LOGIN`            | `true`       | Force SSL for login                                 |
| `AUTOSAVE_INTERVAL`          | `120`        | Autosave interval (seconds)                         |
| `WP_POST_REVISIONS`          | `30`         | Post revisions limit (-1 for unlimited)             |
| `WP_MEMORY_LIMIT`            | `256M`       | Memory limit                                        |
| `WP_MAX_MEMORY_LIMIT`        | `512M`       | Maximum memory limit on Admin                       |
| `WP_CACHE`                   | `false`      | Enable caching                                      |
| `WP_CACHE_KEY_SALT`          | ``           | Cache key salt                                      |
| `WP_TABLE_PREFIX`            | `wp_`        | Database table prefix — change before first install |
| `MEDIA_TRASH`                | `true`       | Enable media trash functionality                    |
| `DISABLE_NAG_NOTICES`        | `true`       | Disable admin nag notices                           |

### Salts

> Salts are generated automatically at startup if they are not defined.

| Variable           | Default | Description                |
| ------------------ | ------- | -------------------------- |
| `AUTH_KEY`         | ``      | Authentication key         |
| `SECURE_AUTH_KEY`  | ``      | Secure authentication key  |
| `LOGGED_IN_KEY`    | ``      | Logged-in key              |
| `NONCE_KEY`        | ``      | Nonce key                  |
| `AUTH_SALT`        | ``      | Authentication salt        |
| `SECURE_AUTH_SALT` | ``      | Secure authentication salt |
| `LOGGED_IN_SALT`   | ``      | Logged-in salt             |
| `NONCE_SALT`       | ``      | Nonce salt                 |

### SMTP

| Variable      | Default | Description                  |
| ------------- | ------- | ---------------------------- |
| `SMTP_USER`   | ``      | SMTP username                |
| `SMTP_PASS`   | ``      | SMTP password                |
| `SMTP_HOST`   | ``      | SMTP host                    |
| `SMTP_FROM`   | ``      | SMTP from email              |
| `SMTP_NAME`   | ``      | SMTP from name               |
| `SMTP_PORT`   | ``      | SMTP port                    |
| `SMTP_SECURE` | ``      | SMTP security type (ssl/tls) |
| `SMTP_AUTH`   | `true`  | Enable SMTP authentication   |
| `SMTP_DEBUG`  | `false` | Enable SMTP debugging        |

### Others

| Variable       | Default         | Description            |
| -------------- | --------------- | ---------------------- |
| `APP_PATH`        | `/site/press`   | Application path                                |
| `UPLOADS_PATH`    | `/site/uploads` | Uploads directory path                          |
| `CACHE_PATH`     | `/site/cache`   | Cache directory path                                                  |
| `LOGS_PATH`      | `/site/logs`    | Logs directory path                                                   |
| `APP_USER`       | `www-data`      | User that owns `/site/press` and runs the php-fpm/nginx **workers**   |
| `APP_GROUP`      | `www-data`      | Group counterpart of `APP_USER`                                       |
| `NGINX_HTTP_PORT` | `80`           | HTTP port the container listens on                                    |
| `NGINX_HTTPS_PORT`| `443`          | HTTPS port the container listens on                                   |
| `TZ`             | `UTC`           | Timezone                                                              |

### PHP

| Variable                            | Default   | Description                                      |
| ----------------------------------- | --------- | ------------------------------------------------ |
| `PHP_MEMORY_LIMIT`                  | `512M`    | Memory limit                                     |
| `PHP_MAX_EXECUTION_TIME`            | `120`     | Max execution time (seconds)                     |
| `PHP_MAX_INPUT_TIME`                | `120`     | Max input time (seconds)                         |
| `PHP_MAX_INPUT_VARS`                | `3000`    | Max input variables                              |
| `PHP_POST_MAX_SIZE`                 | `64M`     | Max POST size                                    |
| `PHP_UPLOAD_MAX_FILESIZE`           | `64M`     | Max upload size                                  |
| `PHP_DEFAULT_SOCKET_TIMEOUT`        | `60`      | Default socket timeout (seconds)                 |
| `PHP_OUTPUT_BUFFERING`              | `4096`    | Output buffering size                            |
| `PHP_PM`                            | `auto`    | Process manager type (`auto`, static, dynamic, ondemand). `auto` picks `static` for ≤2GB containers, `dynamic` otherwise. |
| `PHP_PM_MAX_CHILDREN`               | `auto`    | Max children processes (`auto` sizes from container memory; or set a fixed integer like `50`) |
| `PHP_PM_START_SERVERS`              | `10`      | Start servers (preforked workers)                |
| `PHP_PM_MIN_SPARE_SERVERS`          | `10`      | Min spare servers                                |
| `PHP_PM_MAX_SPARE_SERVERS`          | `35`      | Max spare servers                                |
| `PHP_PM_MAX_REQUESTS`               | `500`     | Max requests per child (prevents memory leaks)   |
| `PHP_PM_PROCESS_IDLE_TIMEOUT`       | `10s`     | Idle timeout for ondemand PM                     |
| `PHP_FPM_REQUEST_TERMINATE_TIMEOUT` | `60`      | Request terminate timeout (seconds)              |
| `PHP_FPM_LISTEN_BACKLOG`            | `65535`   | Listen queue backlog size                        |
| `PHP_FPM_RLIMIT_FILES`              | `65535`   | Max open files limit                             |
| `PHP_OPCACHE_ENABLE`                | `1`       | Enable OPcache                                   |
| `PHP_OPCACHE_MEMORY`                | `256`     | OPcache memory (MB)                              |
| `PHP_OPCACHE_INTERNED_STRINGS`      | `16`      | Interned strings buffer (MB)                     |
| `PHP_OPCACHE_MAX_FILES`             | `20000`   | Max cached files                                 |
| `PHP_OPCACHE_REVALIDATE_FREQ`       | `2`       | Revalidate frequency (seconds)                   |
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS`   | `0`       | Validate timestamps (0 = production; redeploy/restart container to pick up code changes) |
| `PHP_OPCACHE_JIT`                   | `off`     | JIT mode (`tracing`, `function`, `off`). Disabled by default. |
| `PHP_OPCACHE_JIT_BUFFER_SIZE`       | `128M`    | JIT buffer size (only used when JIT is enabled)  |
| `PHP_DISABLE_FUNCTIONS`             | `exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,parse_ini_file,show_source,pcntl_exec` | Comma-separated list of disabled PHP functions (set to empty string to allow all) |
| `PHP_SESSION_COOKIE_HTTPONLY`       | `1`       | Session cookie httponly                          |
| `PHP_SESSION_COOKIE_SECURE`         | `1`       | Session cookie secure                            |
| `PHP_SESSION_USE_STRICT_MODE`       | `1`       | Session use strict mode                          |
| `PHP_APC_ENABLED`                   | `1`       | Enable APCu                                      |
| `PHP_APC_SHM_SIZE`                  | `64M`     | APCu shared memory size                          |
| `PHP_APC_TTL`                       | `7200`    | APCu TTL (seconds)                               |
| `PHP_APC_ENABLE_CLI`                | `0`       | Enable APCu for CLI                              |
| `PHP_REALPATH_CACHE_SIZE`           | `4096K`   | Realpath cache size                              |
| `PHP_REALPATH_CACHE_TTL`            | `600`     | Realpath cache TTL (seconds)                     |

### NGINX

| Variable                            | Default  | Description                                       |
| ----------------------------------- | -------- | ------------------------------------------------- |
| `NGINX_CLIENT_MAX_BODY_SIZE`        | `64m`    | Client max body size                              |
| `NGINX_CLIENT_BODY_BUFFER_SIZE`     | `128k`   | Client body buffer size                           |
| `NGINX_CLIENT_HEADER_BUFFER_SIZE`   | `1k`     | Client header buffer size                         |
| `NGINX_LARGE_CLIENT_HEADER_BUFFERS` | `4 16k`  | Large client header buffers                       |
| `NGINX_OUTPUT_BUFFERS`              | `1 32k`  | Output buffers                                    |
| `NGINX_FASTCGI_BUFFER_SIZE`         | `32k`    | FastCGI buffer size                               |
| `NGINX_FASTCGI_BUFFERS`             | `16 16k` | FastCGI buffers                                   |
| `NGINX_FASTCGI_BUSY_BUFFERS_SIZE`   | `64k`    | FastCGI busy buffers size                         |
| `NGINX_FASTCGI_CONNECT_TIMEOUT`     | `60s`    | FastCGI connect timeout                           |
| `NGINX_FASTCGI_SEND_TIMEOUT`        | `60s`    | FastCGI send timeout                              |
| `NGINX_FASTCGI_READ_TIMEOUT`        | `300s`   | FastCGI read timeout (covers long PHP operations) |
| `NGINX_KEEPALIVE_TIMEOUT`           | `65s`    | Keepalive timeout                                 |
| `NGINX_KEEPALIVE_REQUESTS`          | `1000`   | Requests per keepalive                            |
| `NGINX_CLIENT_BODY_TIMEOUT`         | `60s`    | Client body timeout                               |
| `NGINX_CLIENT_HEADER_TIMEOUT`       | `30s`    | Client header timeout                             |
| `NGINX_SEND_TIMEOUT`                | `60s`    | Send timeout                                      |
| `NGINX_CACHE`                       | `false`  | Enable NGINX FastCGI cache. When set to false, no cache directories or files are created |
| `NGINX_CACHE_MAX_SIZE`              | `512m`   | Cache max size                                    |
| `NGINX_CACHE_INACTIVE`              | `60m`    | Cache inactive time                               |
| `NGINX_CACHE_SPLIT_MOBILE`          | `false`  | Split cache by mobile/desktop user agent          |
| `NGINX_GZIP_COMP_LEVEL`             | `6`      | gzip compression level (1-9)                      |
| `NGINX_BROTLI_COMP_LEVEL`           | `4`      | brotli compression level (0-11) for dynamic content |
| `NGINX_HTTP3`                       | `false`  | Enable HTTP/3 (QUIC) on port 443/udp              |
| `NGINX_SERVER_NAME`                 | derived from `SITEURL` | Override `server_name` directive    |

### SSL

| Variable                    | Default                | Description                              |
| --------------------------- | ---------------------- | ---------------------------------------- |
| `SSL_CERT_PATH`             | `/site/ssl/server.crt` | SSL certificate path                     |
| `SSL_PRIVATE_PATH`          | `/site/ssl/server.key` | SSL private key path                     |
| `SSL_TRUSTED_CERT_PATH`     | `/site/ssl/server.crt` | Trusted CA certificate for OCSP stapling |
| `NGINX_SSL_STAPLING`        | `off`                  | Enable OCSP stapling                     |
| `NGINX_SSL_STAPLING_VERIFY` | `off`                  | Verify OCSP responses                    |

On the first start, if the files at `SSL_CERT_PATH` and `SSL_PRIVATE_PATH` do not exist, a self-signed certificate is generated automatically. Mount `/site/ssl` as a volume to persist it across container recreates and image updates.
Existing files are never overwritten, so providing your own certificate (Let's Encrypt, internal CA, etc.) just works by mounting it at the configured paths.

### NGINX Cache

- On container startup:
  - Any existing NGINX cache directories are always cleaned up first
  - This ensures a clean state when upgrading or changing cache settings

- When `NGINX_CACHE=true`:
  - Cache directories are created in `/site/cache/nginx/fastcgi/`
  - Cache files are generated during operation
  - The `X-FastCGI-Cache` header will be present in responses with values like `HIT`, `MISS`, or `BYPASS`

#### Cache Purging

The cache can be purged using the NGINX Cache Purge module. We recommend using the [NGINX Helper](https://wordpress.org/plugins/nginx-helper/)

### Custom NGINX Configuration

Two empty configuration files are included and loaded at startup. Mount your own versions to extend NGINX without modifying the image.

| File (inside container)                        | Scope                             | When to use                                      |
| ---------------------------------------------- | --------------------------------- | ------------------------------------------------ |
| `/etc/nginx/conf.d/custom-nginx.conf`          | `http {}` block (global)          | Custom upstreams, maps, rate-limit zones, etc.   |
| `/etc/nginx/conf.d/custom-presshost.conf`      | `server {}` block (site-level)    | Extra locations, reverse proxies, rewrites, etc. |

**Example — reverse proxy at `/i/` on the same domain:**

```yaml
# compose.yml
services:
  presshost:
    volumes:
      - ./custom-presshost.conf:/etc/nginx/conf.d/custom-presshost.conf
```

```nginx
# custom-presshost.conf
location /i/ {
    proxy_pass http://image-service:3000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### Logging

All logs are written under `/site/logs` and rotated daily by `logrotate`: `nginx-access.log`, `nginx-error.log`, `php-fpm.log`, `php-error.log`, `php-slow.log`, `cron-presshost.log`, `cron-nginx.log` and `wp-debug.log` (when `WP_DEBUG_LOG=true`).

| Variable       | Default | Description                                                                                                  |
| -------------- | ------- | ------------------------------------------------------------------------------------------------------------ |
| `LOG_LEVEL`    | `WARN`  | `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`. Default shows only errors and serious warnings. |
| `LOG_MAX_SIZE` | `10M`   | Logrotate max size per log file (rotates daily or when exceeded)                                             |
| `LOG_MAX_AGE`  | `7`     | Number of rotated copies to keep (7 days)                                                                    |

### Installation

These variables are used during the interactive installation process via `presshost` command:

| Variable                       | Default  | Description                              |
| ------------------------------ | -------- | ---------------------------------------- |
| `INSTALL_WORDPRESS_VERSION`    | `latest` | Specific WordPress version to install    |
| `INSTALL_CLASSICPRESS_VERSION` | `latest` | Specific ClassicPress version to install |

### Anti-flood / DDoS hardening

PressHost ships with built-in protections that keep PHP/NGINX healthy under load:

| Variable               | Default | Description                                              |
| ---------------------- | ------- | -------------------------------------------------------- |
| `NGINX_RATE_LIMIT`     | `30r/s` | Per-IP request rate (zone `global_limit`)                |
| `NGINX_RATE_BURST`     | `60`    | Burst tolerance before 429                               |
| `NGINX_CONN_LIMIT`     | `50`    | Max simultaneous connections per IP                      |
| `PHP_FPM_REQUEST_TERMINATE_TIMEOUT`  | `60`  | Kill stuck workers after N seconds              |
| `PHP_FPM_REQUEST_SLOWLOG_TIMEOUT`    | `5s`  | Log slow requests                               |
| `PHP_FPM_EMERGENCY_RESTART_THRESHOLD`| `10`  | Crashed workers in interval to trigger master restart |
| `PHP_FPM_EMERGENCY_RESTART_INTERVAL` | `1m`  | Interval for the emergency restart counter      |
| `PHP_FPM_PROCESS_CONTROL_TIMEOUT`    | `10s` | Master/worker IPC timeout                       |

### Custom Constants

Any environment variable starting with `PRESS_` is automatically converted to a Press constant. The `PRESS_` prefix is removed and the value is passed to `wp-config.php`.

> **Security note:** PHP-FPM runs with `clear_env=yes`. The init script forwards an explicit allow-list (`DB_*`, `WP_*`, `SMTP_*`, `AUTH_*`/salts, `PRESS_*`, `INSTALL_*`, `SITEURL`, `TZ`, etc.) into the pool. Variables outside that list are not exposed to PHP - `phpinfo()` will not leak unrelated container env vars.

**Examples:**

| Environment Variable        | Constant                         | Type    |
| --------------------------- | -------------------------------- | ------- |
| `PRESS_GOOGLE_KEY=abc123`   | `define('GOOGLE_KEY', 'abc123')` | string  |
| `PRESS_ENABLE_FEATURE=true` | `define('ENABLE_FEATURE', true)` | boolean |
| `PRESS_MAX_ITEMS=50`        | `define('MAX_ITEMS', 50)`        | integer |

### Using signed SSL

#### Via Certbot / Let's Encrypt

```yaml
services:
  presshost:
    image: ghcr.io/butialabs/presshost:latest
    environment:
      # ...
      SSL_CERT_PATH: /site/ssl/live/your-domain.com/fullchain.pem
      SSL_PRIVATE_PATH: /site/ssl/live/your-domain.com/privkey.pem
      SSL_TRUSTED_CERT_PATH: /site/ssl/live/your-domain.com/chain.pem
      NGINX_SSL_STAPLING: "on"
      NGINX_SSL_STAPLING_VERIFY: "on"
    volumes:
      # ...
      - /etc/certbot:/site/ssl:ro
```

> **Note:** The `SSL_TRUSTED_CERT_PATH` variable should point to the intermediate certificate chain (`chain.pem`) for OCSP stapling to work correctly. Without this, you may see warnings like "ssl_stapling ignored, no OCSP responder URL in the certificate".

> **Note:** Nginx automatically reloads daily at 00:00 (container timezone) to pick up renewed certificates. This ensures seamless certificate rotation without manual intervention.


## Performance Tuning

### FastCGI Page Cache

Nginx caches the rendered HTML of anonymous (non-logged-in) requests and serves it directly.

```yaml
environment:
  NGINX_CACHE: "true"
  NGINX_CACHE_MAX_SIZE: "1g"   # total disk space for the cache
  NGINX_CACHE_INACTIVE: "60m"  # evict pages not hit in this window
```

Cache is automatically bypassed for logged-in users, WooCommerce cart/checkout, wp-admin, POST requests, and WordPress preview mode.
For on-demand purge from the WordPress admin, install the [NGINX Helper](https://wordpress.org/plugins/nginx-helper/) plugin and point it at the FastCGI cache.

### Valkey Object Cache

Stores WordPress object-cache data (database query results, transients) in Valkey so they survive across requests and processes.

```yaml
services:
  presshost:
    environment:
      WP_CACHE: "true"
      WP_REDIS_HOST: valkey
      WP_REDIS_PORT: 6379

  valkey:
    image: valkey/valkey:8-alpine
    container_name: valkey
    restart: unless-stopped
    command: valkey-server --maxmemory 256mb --maxmemory-policy allkeys-lru --save ""
    networks:
      - presshost
```

Then install and activate the [Redis Object Cache](https://wordpress.org/plugins/redis-cache/) plugin inside WordPress.

### OPcache JIT (PHP 8.4)

PHP 8.4 includes a JIT compiler that can improve throughput on CPU-bound workloads (WooCommerce, page builders, image processing).
It is disabled by default because a small number of plugins with legacy code may behave incorrectly with JIT enabled.

```yaml
environment:
  PHP_OPCACHE_JIT: "tracing"       # recommended mode for WordPress
  PHP_OPCACHE_JIT_BUFFER_SIZE: "128M"
```

### CLI and Tips:

#### Installer

The container ships with the `presshost` CLI. Launch it with:

```bash
docker exec -it presshost presshost
```

When **no WordPress/ClassicPress** is installed yet, the menu lets you:

1. **Install WordPress**: downloads `wordpress.org/latest.zip` (or a specific version), unpacks it to `/site/press`, generates `wp-config.php` + `wp-secrets.php` (locally generated salts, no external API), runs `wp core install`, and resets ownership of the install directory to `www-data:www-data`.
2. **Install ClassicPress**: same flow, pulling from the official ClassicPress release archive.

When a site is **already installed**, the menu offers:

1. **View installation info**: shows detected type (WordPress/ClassicPress), version, site URL, title and the configured directories (`/site/press`, `/site/uploads`, `/site/cache`).
2. **Exit**.

You can also invoke the installer non-interactively:

```bash
# Same flows scripted via env vars (no TTY required)
docker exec -e PRESSHOST_DEFAULT_ACTION=wordpress \
            -e INSTALL_URL=https://example.com \
            -e INSTALL_EMAIL=admin@example.com \
            -it presshost presshost
```

#### Fix permissions

`presshost fix-perms` resets ownership to `www-data:www-data` and applies safe permissions (`755` for directories, `644` for files, `640` for `wp-config.php` and `wp-secrets.php`) on `/site/{press,uploads,cache,logs}`. It must be invoked with the root account inside the container:

```bash
docker exec -u 0 presshost presshost fix-perms
```

---

**Made with ❤️ by [Butiá Labs](https://butialabs.com)**
