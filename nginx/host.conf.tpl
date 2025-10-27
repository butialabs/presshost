server {
	listen 443 ssl;
	listen [::]:443 ssl;
    listen 443 quic reuseport;
    listen [::]:443 quic reuseport;
	http2 on;
	include global/http3.conf;
	
	# Server name to listen for
	server_name {{SSL_DOMAIN}};

	# Path to document root
	root /site/press;

	# Paths to certificate files.
    ssl_certificate /etc/letsencrypt/live/{{SSL_DOMAIN}}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{{SSL_DOMAIN}}/privkey.pem;

	# File to be used as index
	index index.php;

	# SSL rules
	include global/ssl.conf;

	# Skip cache rules
	include global/skip_cache.conf;

	# Exclusions
	include global/exclusions.conf;

	# Security
	include global/security.conf;

	# Rewrite urls configuration
	include global/rewrite.conf;

	# Cloudflare
	include global/cloudflare.conf;

	location / {
		try_files $uri $uri/ /index.php?$args;
	}

	location ~ \.php$ {
		try_files $uri =404;

		include global/fastcgi-params.conf;
		fastcgi_pass   $upstream;
	}

	# Caches images, icons, video, audio, etc.
    location ~* ^.+\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$ {
        access_log off;
		log_not_found off;
		expires max;
    }

	# Cache WebFonts.
	location ~* \.(?:ttf|ttc|otf|eot|woff|woff2)$ {
		expires max;
		access_log off;
		add_header Access-Control-Allow-Origin *;
	}
}

server {
    listen 80;
    listen [::]:80;
    server_name {{SSL_DOMAIN}} www.{{SSL_DOMAIN}};
    
    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
	listen 443 ssl;
	listen [::]:443 ssl;
	http2 on;
	
	server_name www.{{SSL_DOMAIN}};

	return 301 https://{{SSL_DOMAIN}}$request_uri;
}