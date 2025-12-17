[program:cron]
command=/usr/sbin/cron -f
autostart=true
autorestart=true
priority=15
stdout_logfile=/dev/null
stdout_logfile_maxbytes=0
stderr_logfile=/dev/null
stderr_logfile_maxbytes=0
