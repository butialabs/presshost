# PressHost 🚀

> Production-ready Docker image for WordPress and ClassicPress hosting with NGINX, PHP 8.4, SSL/TLS, and HTTP/3 support.

[![Docker Image](https://img.shields.io/badge/docker-presshost-blue.svg)](https://github.com/butialabs/presshost)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PHP Version](https://img.shields.io/badge/php-8.4-purple.svg)](https://www.php.net/)
[![NGINX](https://img.shields.io/badge/nginx-1.28-brightgreen.svg)](https://nginx.org/)

## ✨ Features

- 🚄 **High Performance** - Optimized NGINX with HTTP/3 (QUIC) support
- 🔒 **Automatic SSL** - Let's Encrypt integration with auto-renewal
- ☁️ **Cloudflare Ready** - Built-in Real IP detection
- 🐳 **Docker Native** - Easy deployment with volume management
- ⚙️ **Environment-based Config** - No wp-config.php editing needed
- 🔧 **WP-CLI Included** - Full WordPress management from command line
- 📦 **Dual CMS Support** - Works with both WordPress and ClassicPress
- 💾 **Disk Cache Support** - Optimized for WP Super Cache, W3 Total Cache, and WP Fastest Cache

## 🎬 Quick Start

### 1. Create Directory Structure

```bash
mkdir -p /opt/{press,uploads,cache,ssl/{letsencrypt,certbot,certs},logs}
```

### 2. Setup Environment

```bash
cp .env.sample .env
nano .env  # Configure your settings
```

### 3. Launch with Docker Compose

```yaml
services:
  app:
    image: ghcr.io/altendorfme/presshost:latest
    ports:
      - "80:80"
      - "443:443/tcp"
      - "443:443/udp"
    env_file: .env
    volumes:
      - /opt/press:/site/press
      - /opt/uploads:/site/uploads
      - /opt/cache:/site/cache
      - /opt/ssl/letsencrypt:/etc/letsencrypt
      - /opt/logs:/var/log
```

```bash
docker-compose up -d
```

### 4. Install WordPress or ClassicPress

```bash
# For WordPress
docker exec -it app download-wordpress

# For ClassicPress
docker exec -it app download-classicpress
```

### 5. Complete Installation

```bash
docker exec -it app wp core install \
  --url="https://yourdomain.com" \
  --title="My Awesome Site" \
  --admin_user="admin" \
  --admin_password="secure_password" \
  --admin_email="admin@yourdomain.com" \
  --allow-root
```

That's it! Your site is now live at `https://yourdomain.com` 🎉

## 📚 Documentation

### Volume Structure

**Important:** The volume structure is mandatory for proper operation.

```
/opt/
├── press/         → WordPress/ClassicPress files (/site/press)
├── uploads/       → Media uploads (/site/uploads) - MUST be separate
├── cache/         → Plugin cache files (/site/cache)
├── ssl/
│   ├── letsencrypt/  → SSL certificates
│   ├── certbot/      → Certbot webroot
│   └── certs/        → Additional certificates
└── logs/          → Application logs
```

⚠️ **Critical Notes:**
- `wp-config.php` is provided by the image - configure via environment variables
- Uploads **must** be in `/site/uploads` (not `/site/press/wp-content/uploads`)
- Cache directory is automatically symlinked to `/site/press/wp-content/cache`
- Never edit `wp-config.php` directly - use `.env` file instead

### Cache Directory

The cache directory is separated from WordPress files for better performance and easier management:

```
/opt/cache/        → Plugin cache files (/site/cache)
  ├── page/        → Page cache
  ├── minify/      → Minified CSS/JS
  ├── object/      → Object cache (if disk-based)
  ├── db/          → Database query cache
  └── tmp/         → Temporary files
```

**Benefits:**
- 🚀 Cache isolated from code for better backup strategies
- 📊 Easy monitoring of cache size
- 🗑️ Simple cache purging without affecting WordPress files
- ⚡ Optimized NGINX serving of cached files

### Environment Variables

#### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SSL_DOMAIN` | Your domain name | `example.com` |
| `DB_NAME` | Database name | `presshost` |
| `DB_USER` | Database user | `presshost` |
| `DB_PASSWORD` | Database password | `secure_password` |
| `DB_HOST` | Database host | `mariadb` |
| `WP_SITEURL` | Site URL | `https://example.com` |
| `WP_HOME` | Site URL | `https://example.com` |
| `AUTH_KEY` | Security key | Generate at [WordPress.org](https://api.wordpress.org/secret-key/1.1/salt/) |

See [`.env.sample`](docs/.env.sample) for all available options.

## 🎯 Usage Scenarios

### New Press Installation

Perfect for starting a fresh Press site:

```bash
# Create volumes
mkdir -p /opt/{press,uploads,cache,ssl/{letsencrypt,certbot,certs},logs}

# Configure environment
cp docs/.env.sample .env
# Edit .env with your settings

# Start services
docker-compose up -d

# Download WordPress
docker exec -it app download-wordpress
## OR
docker exec -it app download-classicpress

# Install
docker exec -it app wp core install \
  --url="https://yourdomain.com" \
  --title="My Site" \
  --admin_user="admin" \
  --admin_password="password" \
  --admin_email="admin@example.com" \
  --allow-root
```

### Existing Press Site

Migrate your existing Press installation:

```bash
# Copy your Press files (excluding wp-config.php)
rsync -av --exclude='wp-config.php' /path/to/presshost/ /opt/press/

# Copy your uploads
cp -r /path/to/uploads/* /opt/uploads/

# Configure .env with your database credentials
nano .env

# Start services
docker-compose up -d
```

**Note:** Remove your old `wp-config.php` - the image provides a properly configured one.

### Building Custom Image with WordPress/ClassicPress

Create your own image with WordPress or ClassicPress pre-installed:

#### 1. Create a Dockerfile

```dockerfile
FROM ghcr.io/altendorfme/presshost:latest
COPY --chown=www-data:www-data ./press /site/press
```

#### 2. Build Your Image

```bash
docker build -t my-presshost-site:latest .
```

#### 3. Use in Docker Compose

```yaml
services:
  app:
    image: my-presshost-site:latest
    ports:
      - "80:80"
      - "443:443/tcp"
      - "443:443/udp"
    env_file: .env
    volumes:
      - /opt/uploads:/site/uploads
      - /opt/cache:/site/cache
      - /opt/ssl/letsencrypt:/etc/letsencrypt
      - /opt/logs:/var/log
```

## 💾 Cache Plugin Configuration

PressHost includes optimized support for disk-based cache plugins:

### Supported Plugins

✅ **WP Super Cache** - Simple, reliable page caching
✅ **W3 Total Cache** - Advanced caching with minification
✅ **WP Fastest Cache** - Fast and easy cache solution
✅ **Cache Enabler** - Lightweight disk cache
✅ **Comet Cache** - Advanced caching features

## 🔧 Common Tasks

### WP-CLI Commands

```bash
# Update core
docker exec -it app wp core update --allow-root

# Install plugins
docker exec -it app wp plugin install wordpress-seo --activate --allow-root

# Update all plugins
docker exec -it app wp plugin update --all --allow-root

# Database operations
docker exec -it app wp db export backup.sql --allow-root

# Clear cache
docker exec -it app wp cache flush --allow-root
```

### Service Management

```bash
# View logs
docker-compose logs -f app

# Restart services
docker exec -it app supervisorctl restart nginx
docker exec -it app supervisorctl restart php-fpm

# Service status
docker exec -it app supervisorctl status

# Access shell
docker exec -it app bash
```

### SSL Certificate Management

Certificates are automatically generated and renewed. For manual operations:

```bash
# Manual renewal
docker exec -it app certbot renew

# Force renewal
docker exec -it app certbot renew --force-renewal
```

## 🔒 Security Features

- ✅ Automatic HTTPS with Let's Encrypt
- ✅ HTTP/3 with QUIC protocol
- ✅ DH parameters for strong encryption
- ✅ Cloudflare Real IP detection
- ✅ File editing disabled in admin
- ✅ Automatic updates configurable
- ✅ Secure environment-based configuration

## 🚀 Performance Optimizations

- **PHP 8.4** - Latest PHP with performance improvements
- **OPcache** - Bytecode caching enabled
- **APCu** - Object caching support
- **Redis Ready** - Compatible with Redis object cache
- **Disk Cache Support** - Optimized for popular cache plugins
- **FastCGI Cache** - NGINX caching configured
- **HTTP/3** - Next-generation protocol support

## 🐛 Troubleshooting

### Certificate Not Generated

1. Ensure domain is correctly pointed to your server
2. Check ports 80 and 443 are open
3. View logs: `docker-compose logs app`

### Permission Issues

```bash
docker exec -it app chown -R www-data:www-data /site/press /site/uploads /site/cache
docker exec -it app chmod -R 755 /site/press /site/uploads /site/cache
```

### Database Connection Error

1. Verify credentials in `.env`
2. Ensure MariaDB is running: `docker-compose ps`
3. Test connection: `docker exec -it app mysql -h mariadb -u presshost -p`

## 📖 Additional Documentation

- [Environment Variables](docs/.env.sample) - Complete configuration reference
- [Docker Compose Example](docs/compose.yml) - Full docker-compose setup
- [Cache Architecture](docs/CACHE_ARCHITECTURE.md) - Technical cache implementation details
- [Cache Plugins Guide](docs/CACHE_PLUGINS_GUIDE.md) - Step-by-step plugin configuration

## 🌟 Like it? Help Out!

If you find this plugin useful, consider:

- ⭐ Starring the repository
- 🐛 Reporting bugs you find
- 💡 Suggesting improvements
- 🤝 Contributing code
- 📢 Sharing with others

---

**Made with ❤️ by Butiá Labs and Manual do Usuário**