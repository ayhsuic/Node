# syntax=docker/dockerfile:1
FROM nginx:alpine

RUN <<EOF cat > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;

events {
    worker_connections 1024;
}

stream {
    resolver 1.1.1.1 8.8.8.8 valid=300s;
    resolver_timeout 5s;

    server {
        listen 7860;
        ssl_preread on;
        proxy_pass \$ssl_preread_server_name:\$server_port;
    }
}

EOF

CMD ["nginx", "-g", "daemon off;"]
