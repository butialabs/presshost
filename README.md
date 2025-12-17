# PressHost 🚀

> Docker image for WordPress and ClassicPress hosting with NGINX and PHP 8.4.

[![Docker Image](https://img.shields.io/badge/docker-presshost-blue.svg)](https://github.com/butialabs/presshost)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PHP Version](https://img.shields.io/badge/php-8.4-purple.svg)](https://www.php.net/)
[![NGINX](https://img.shields.io/badge/nginx-1.26-brightgreen.svg)](https://nginx.org/)

## Features

- **High Performance** - Based on Debian 13/PHP/NGINX
- **CMS Support** - Works with both WordPress and ClassicPress
- **Rootless by Default** - Runs as non-root user for security
- **Environment-based** - PHP/NGINX/WordPress/ClassicPress settings via environment variables, no wp-config.php editing needed
- **Cache Support** - Optimized for WP Super Cache, W3 Total Cache, WP Fastest Cache and NGINX FastCGI Cache (NGINX Helper)

## Quick Start

```bash
wget https://raw.githubusercontent.com/butialabs/presshost/main/compose.yml
nano compose.yml
docker compose up -d
```

### Required variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_NAME` | Database name | `presshost` |
| `DB_USER` | Database user | `presshost` |
| `DB_PASSWORD` | Database password | `p@ssw0rd` |
| `DB_HOST` | Database host | `db` |
| `WP_SITEURL` | Site URL | `https://your-domain.xyz` |
| `WP_HOME` | Home URL | `https://your-domain.xyz` |


### Volumes

| Path | Description |
|------|-------------|
| `/site/press` | WordPress/ClassicPress files |
| `/site/uploads` | Media files (wp-content/uploads) |
| `/site/cache` | Cache files |
| `/site/logs` | Log files |


## Installation

> If it's a migration, you can skip the installation and just copy the files to the correct volumes.

> Upon startup, an index.php file would be displayed automatically if none already exists.

After starting your container, run the interactive installer:

```bash
docker exec -it presshost ./presshost
```

The installer will guide you through WordPress or ClassicPress installation.

## Environment

### PHP

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_MEMORY_LIMIT` | `256M` | Memory limit |
| `PHP_MAX_EXECUTION_TIME` | `300` | Max execution time |
| `PHP_POST_MAX_SIZE` | `64M` | Max POST size |
| `PHP_UPLOAD_MAX_FILESIZE` | `64M` | Max upload size |

### Other

| Variable | Default | Description |
|----------|---------|-------------|
| `VERBOSE` | `false` | Enable verbose logging |
| `SSL_CERT_PATH` | `/etc/nginx/server.crt` | SSL certificate path |
| `SSL_PRIVATE_PATH` | `/etc/nginx/server.key` | SSL private key path |
| `NGINX_SSL_STAPLING` | `off` | Enable OCSP stapling |
| `NGINX_SSL_STAPLING_VERIFY` | `off` | Verify OCSP responses |

### Custom Constants

Any environment variable starting with `PRESS_` is automatically converted to a Press constant. The `PRESS_` prefix is removed and the value is passed to `wp-config.php`.

**Examples:**

| Environment Variable | WordPress Constant | Type |
|---------------------|-------------------|------|
| `PRESS_GOOGLE_KEY=abc123` | `define('GOOGLE_KEY', 'abc123')` | string |
| `PRESS_ENABLE_FEATURE=true` | `define('ENABLE_FEATURE', true)` | boolean |
| `PRESS_MAX_ITEMS=50` | `define('MAX_ITEMS', 50)` | integer |

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
