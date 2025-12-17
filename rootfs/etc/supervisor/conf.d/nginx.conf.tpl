[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
priority=10
stdout_logfile=/dev/null
stdout_logfile_maxbytes=0
stderr_logfile=/dev/null
stderr_logfile_maxbytes=0
