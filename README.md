# PressHost 🚀

> Docker image for WordPress and ClassicPress hosting with NGINX and PHP 8.4.

[![Docker Image](https://img.shields.io/badge/docker-presshost-blue.svg)](https://github.com/butialabs/presshost)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PHP Version](https://img.shields.io/badge/php-8.4-purple.svg)](https://www.php.net/)
[![NGINX](https://img.shields.io/badge/nginx-1.26-brightgreen.svg)](https://nginx.org/)

## Features

- ⚡ Based on Debian + NGINX 1.26 + PHP 8.4
- 🔐 Rootless by default
- 🌱 Everything is done via environment variables; PHP configurations, NGINX, and even WordPress constants are handled by environment variables. No need to edit wp-config.php.
- 🧠 Real caching support, works well with WP Super Cache, W3 Total Cache, WP Fastest Cache, and also with NGINX FastCGI Cache (via NGINX Helper).
- 📦 Separate code, uploads, cache, and logs — facilitates backup, restore, and migration.
- 🔧 Interactive installer, start the container, run `docker exec -it presshost ./presshost` and perform the guided installation.

## Quick Start

```bash
wget https://raw.githubusercontent.com/butialabs/presshost/main/compose.yml
nano compose.yml
docker compose up -d
```

### Required variables

| Variable      | Description       | Example                   |
| ------------- | ----------------- | ------------------------- |
| `DB_NAME`     | Database name     | `presshost`               |
| `DB_USER`     | Database user     | `presshost`               |
| `DB_PASSWORD` | Database password | `p@ssw0rd`                |
| `DB_HOST`     | Database host     | `db`                      |
| `WP_SITEURL`  | Site URL          | `https://your-domain.xyz` |
| `WP_HOME`     | Home URL          | `https://your-domain.xyz` |

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

After starting your container, run the interactive installer:

```bash
docker exec -it presshost ./presshost
```

The installer will guide you through WordPress or ClassicPress installation.

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
| `WP_POST_REVISIONS`          | `-1`         | Post revisions limit (-1 for unlimited)             |
| `WP_MEMORY_LIMIT`            | `512M`       | Memory limit                                        |
| `WP_MAX_MEMORY_LIMIT`        | `512M`       | Maximum memory limit                                |
| `WP_CACHE`                   | `false`      | Enable caching                                      |
| `WP_CACHE_KEY_SALT`          | ``           | Cache key salt                                      |
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
| `APP_PATH`     | `/site/press`   | Application path       |
| `UPLOADS_PATH` | `/site/uploads` | Uploads directory path |
| `CACHE_PATH`   | `/site/cache`   | Cache directory path   |
| `LOGS_PATH`    | `/site/logs`    | Logs directory path    |
| `APP_USER`     | `www-data`      | Application user       |
| `APP_GROUP`    | `www-data`      | Application group      |

### PHP

| Variable                          | Default   | Description                                      |
| --------------------------------- | --------- | ------------------------------------------------ |
| `PHP_MEMORY_LIMIT`                | `256M`    | Memory limit                                     |
| `PHP_MAX_EXECUTION_TIME`          | `300`     | Max execution time                               |
| `PHP_POST_MAX_SIZE`               | `64M`     | Max POST size                                    |
| `PHP_UPLOAD_MAX_FILESIZE`         | `64M`     | Max upload size                                  |
| `PHP_MAX_INPUT_TIME`              | `60`      | Max input time                                   |
| `PHP_MAX_INPUT_VARS`              | `1000`    | Max input variables                              |
| `PHP_PM`                          | `dynamic` | Process manager type (static, dynamic, ondemand) |
| `PHP_PM_MAX_CHILDREN`             | `20`      | Max children processes                           |
| `PHP_PM_START_SERVERS`            | `2`       | Start servers                                    |
| `PHP_PM_MIN_SPARE_SERVERS`        | `1`       | Min spare servers                                |
| `PHP_PM_MAX_SPARE_SERVERS`        | `3`       | Max spare servers                                |
| `PHP_PM_MAX_REQUESTS`             | `500`     | Max requests per child                           |
| `PHP_OPCACHE_ENABLE`              | `1`       | Enable OPcache                                   |
| `PHP_OPCACHE_MEMORY`              | `128`     | OPcache memory (MB)                              |
| `PHP_OPCACHE_INTERNED_STRINGS`    | `16`      | Interned strings buffer (MB)                     |
| `PHP_OPCACHE_MAX_FILES`           | `10000`   | Max cached files                                 |
| `PHP_OPCACHE_REVALIDATE_FREQ`     | `2`       | Revalidate frequency (seconds)                   |
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS` | `1`       | Validate timestamps                              |
| `PHP_SESSION_COOKIE_HTTPONLY`     | `1`       | Session cookie httponly                          |
| `PHP_SESSION_COOKIE_SECURE`       | `1`       | Session cookie secure                            |
| `PHP_SESSION_USE_STRICT_MODE`     | `1`       | Session use strict mode                          |
| `PHP_APC_ENABLED`                 | `0`       | Enable APC                                       |
| `PHP_APC_SHM_SIZE`                | `32M`     | APC shared memory size                           |
| `PHP_APC_TTL`                     | `3600`    | APC TTL (seconds)                                |
| `PHP_APC_ENABLE_CLI`              | `0`       | Enable APC for CLI                               |
| `PHP_REALPATH_CACHE_SIZE`         | `16K`     | Realpath cache size                              |
| `PHP_REALPATH_CACHE_TTL`          | `120`     | Realpath cache TTL (seconds)                     |

### NGINX

| Variable                            | Default | Description                 |
| ----------------------------------- | ------- | --------------------------- |
| `NGINX_CLIENT_MAX_BODY_SIZE`        | `64M`   | Client max body size        |
| `NGINX_CACHE_MAX_SIZE`              | `1g`    | Cache max size              |
| `NGINX_CACHE_INACTIVE`              | `60m`   | Cache inactive time         |
| `NGINX_CLIENT_BODY_BUFFER_SIZE`     | `128k`  | Client body buffer size     |
| `NGINX_CLIENT_HEADER_BUFFER_SIZE`   | `1k`    | Client header buffer size   |
| `NGINX_LARGE_CLIENT_HEADER_BUFFERS` | `4 16k` | Large client header buffers |
| `NGINX_OUTPUT_BUFFERS`              | `2 32k` | Output buffers              |
| `NGINX_FASTCGI_BUFFER_SIZE`         | `128k`  | FastCGI buffer size         |
| `NGINX_FASTCGI_BUFFERS`             | `8 16k` | FastCGI buffers             |
| `NGINX_FASTCGI_BUSY_BUFFERS_SIZE`   | `256k`  | FastCGI busy buffers size   |
| `NGINX_CACHE`                       | `true`  | Enable NGINX cache          |

### SSL

| Variable                    | Default                 | Description           |
| --------------------------- | ----------------------- | --------------------- |
| `SSL_CERT_PATH`             | `/etc/nginx/server.crt` | SSL certificate path  |
| `SSL_PRIVATE_PATH`          | `/etc/nginx/server.key` | SSL private key path  |
| `NGINX_SSL_STAPLING`        | `off`                   | Enable OCSP stapling  |
| `NGINX_SSL_STAPLING_VERIFY` | `off`                   | Verify OCSP responses |

### Logging

| Variable       | Default | Description               |
| -------------- | ------- | ------------------------- |
| `VERBOSE`      | `false` | Enable verbose logging    |
| `LOG_MAX_SIZE` | `10M`   | Log max size for rotation |
| `LOG_MAX_AGE`  | `30`    | Log max age for rotation  |

### Custom Constants

Any environment variable starting with `PRESS_` is automatically converted to a Press constant. The `PRESS_` prefix is removed and the value is passed to `wp-config.php`.

**Examples:**

| Environment Variable        | Constant                         | Type    |
| --------------------------- | -------------------------------- | ------- |
| `PRESS_GOOGLE_KEY=abc123`   | `define('GOOGLE_KEY', 'abc123')` | string  |
| `PRESS_ENABLE_FEATURE=true` | `define('ENABLE_FEATURE', true)` | boolean |
| `PRESS_MAX_ITEMS=50`        | `define('MAX_ITEMS', 50)`        | integer |

### Using signed SSL

#### Via Nginx Proxy Manager

```yaml
services:
  presshost:
    image: ghcr.io/butialabs/presshost:latest
    environment:
      # ...
      SSL_CERT_PATH: /etc/letsencrypt/live/npm-{id}/fullchain.pem
      SSL_PRIVATE_PATH: /etc/letsencrypt/live/npm-{id}/privkey.pem
      NGINX_SSL_STAPLING: "on"
      NGINX_SSL_STAPLING_VERIFY: "on"
    volumes:
      # ...
      - /opt/npm/letsencrypt:/etc/letsencrypt:ro
```

> **Note:** Nginx automatically reloads daily at 00:00 (container timezone) to pick up renewed certificates. This ensures seamless certificate rotation without manual intervention.

---

**Made with ❤️ by [Butiá Labs](https://butialabs.com)**
