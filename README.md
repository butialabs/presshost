# PressHost 🚀

> Production-ready Docker image for WordPress and ClassicPress hosting with NGINX, PHP 8.4, optimized performance, and flexible SSL/HTTPS options.

[![Docker Image](https://img.shields.io/badge/docker-presshost-blue.svg)](https://github.com/butialabs/presshost)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PHP Version](https://img.shields.io/badge/php-8.4-purple.svg)](https://www.php.net/)
[![NGINX](https://img.shields.io/badge/nginx-latest-brightgreen.svg)](https://nginx.org/)

## ✨ Features

- 🚄 **High Performance** - Based on optimized shinsenter/php:8.4-fpm-nginx
- 🔒 **Flexible SSL** - Multiple deployment options (Cloudflare, NPM, Traefik)
- 🔐 **Rootless by Default** - Runs as non-root user for security
- ⚡ **Dynamic Configuration** - PHP settings via environment variables (no rebuild needed)
- 🐳 **Docker Native** - Easy deployment with volume management  
- ⚙️ **Environment-based Config** - No wp-config.php editing needed
- 🔧 **WP-CLI Included** - Full WordPress management from command line
- 📦 **Dual CMS Support** - Works with both WordPress and ClassicPress
- 💾 **Cache Support** - Optimized for WP Super Cache, W3 Total Cache, WP Fastest Cache

## 🎬 Quick Start

```bash
# 1. Create directory structure
sudo mkdir -p /opt/{press,uploads,cache,mariadb/data,logs}

# 2. Set ownership for rootless (UID 1000)
sudo useradd -r -u 1000 presshost
sudo chown -R 1000:1000 /opt/{press,uploads,cache,logs}
sudo chown -R 999:999 /opt/{mariadb}

# 3. Start services
wget https://raw.githubusercontent.com/butialabs/presshost/refs/heads/main/docker-compose.yml
```

## 🚀 Install Wordpress/Classicpress

You can automatically install WordPress or ClassicPress when the container starts by setting the `INSTALL_PRESS` environment variable:

```bash
# For WordPress
INSTALL_PRESS=wordpress

# For ClassicPress
INSTALL_PRESS=classicpress
```

Add this to your `docker-compose.yml`:

```yaml
services:
  app:
    environment:
      - INSTALL_PRESS=wordpress  # or classicpress
```

Or pass it directly when running the container:

```bash
docker exec -it presshost install-wordpress
# OR
docker exec -it presshost install-classicpress
```

**That's it!** Your site is live at `http://yourdomain.com:8080` or `http://yourdomain.com:8443`

**Note:** Automatic installation only runs if no existing WordPress/ClassicPress installation is detected (checks for [`wp-load.php`](hooks/00-init.sh:162)). This prevents accidental overwrites of existing installations.

### Directory Structure

```
/opt/
├── press/              → WordPress/ClassicPress files (/site/press)
├── uploads/            → Media uploads (/site/uploads)
├── cache/              → Plugin cache files (/site/cache)
├── redis/data/         → Redis persistence
├── mariadb/data/       → Database files
├── logs/               → Application logs
└── npm/                → NGINX Proxy Manager (if used)
    ├── data/
    └── letsencrypt/
```

⚠️ **Important Notes:**
- `wp-config.php` is provided by the image - configure via environment variables
- Uploads **must** be in `/site/uploads` (automatically symlinked)
- Cache directory is automatically symlinked to `/site/press/wp-content/cache`
- Never edit `wp-config.php` directly - use `.env` file instead

## 🔧 Common Tasks

### WP-CLI Commands

```bash
# Update WordPress core
docker exec -it presshost wp core update --allow-root

# Install plugins
docker exec -it presshost wp plugin install wordpress-seo --activate --allow-root

# Update all plugins
docker exec -it presshost wp plugin update --all --allow-root

# Database operations
docker exec -it presshost wp db export backup.sql --allow-root
docker exec -it presshost wp db optimize --allow-root

# Clear cache
docker exec -it presshost wp cache flush --allow-root
```

### Service Management

```bash
# View logs
docker-compose logs -f app

# Restart container
docker-compose restart app

# Access shell
docker exec -it presshost bash

# Check PHP configuration
docker exec -it presshost php -i
```

## 🐛 Troubleshooting

### Permission Issues

```bash
# Verify container user
docker exec presshost whoami  # Should be: www-data
docker exec presshost id      # Should be: uid=1000

# Fix permissions
sudo chown -R 1000:1000 /opt/{press,uploads,cache}
```

### WordPress Can't Upload Files

```bash
# Ensure uploads directory has correct permissions
sudo chown -R 1000:1000 /opt/uploads
sudo chmod -R 755 /opt/uploads
```

## Credits

This project is built upon the excellent work of:

- **[shinsenter/php](https://github.com/shinsenter/php)** - High-performance PHP-FPM and NGINX Docker images that serve as the foundation for PressHost
- **[WordOps](https://github.com/WordOps/WordOps)** - NGINX configurations and WordPress optimization techniques inspired by this amazing project

##  License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Made with ❤️ by [Butiá Labs](https://butialabs.com)**