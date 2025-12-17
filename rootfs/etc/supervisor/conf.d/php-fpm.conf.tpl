[program:php-fpm]
command=/usr/sbin/php-fpm8.4 -F
autostart=true
autorestart=true
priority=5
stdout_logfile=/dev/null
stdout_logfile_maxbytes=0
stderr_logfile=/dev/null
stderr_logfile_maxbytes=0
