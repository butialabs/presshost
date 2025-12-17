[supervisord]
nodaemon=true
user=root
logfile=${LOGS_PATH}/supervisor.log
pidfile=/var/run/supervisord.pid
childlogdir=${LOGS_PATH}

[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
