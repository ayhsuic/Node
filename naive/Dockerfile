# syntax=docker/dockerfile:1

FROM caddy:2.7.5-builder-alpine AS builder
RUN xcaddy build \
    --with github.com/caddyserver/forwardproxy=github.com/klzgrad/forwardproxy@naive

FROM caddy:2.7.5-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

ENV DOMAIN=
ENV EMAIL=ayhsuic@outlook.com
ENV UPSTREAM=https://cn.bing.com
ENV NAIVE_USER=user
ENV NAIVE_PASS=password

EXPOSE 80 443 443/udp

COPY <<EOF /etc/caddy/Caddyfile
:443, \${DOMAIN} {
    tls \${EMAIL}
    route {
        # 用户 1
        forward_proxy {
            basic_auth \${NAIVE_USER} \${NAIVE_PASS}
            hide_ip
            hide_via
            probe_resistance
        }

        reverse_proxy \${UPSTREAM} {
            header_up Host {upstream_hostport}
            header_up X-Forwarded-Host {host}
        }
    }
}
EOF

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]