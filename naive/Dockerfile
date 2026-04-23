# syntax=docker/dockerfile:1

FROM caddy:2.7.5-builder-alpine AS builder
RUN xcaddy build \
    --with github.com/caddyserver/forwardproxy=github.com/klzgrad/forwardproxy@naive

FROM caddy:2.7.5-alpine

RUN apk add --no-cache git ca-certificates

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

RUN git clone https://github.com/ayhsuic/ayhsuic.github.io.git /var/www/html

ENV DOMAIN=
ENV EMAIL=ayhsuic@outlook.com
ENV PROXY_USER=user
ENV PROXY_PASS=password

EXPOSE 80 443 443/udp

COPY <<EOF /etc/caddy/Caddyfile
{
    order forward_proxy before file_server
}

:443, \${DOMAIN} {
    tls \${EMAIL}
    
    forward_proxy {
        basic_auth \${PROXY_USER} \${PROXY_PASS}
        hide_ip
        hide_via
        probe_resistance
    }
    
    file_server {
        root /var/www/html
    }
}
EOF

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
