# syntax=docker/dockerfile:1
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
RUN xcaddy build --with github.com/klzgrad/forwardproxy@naive
FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /go/bin/caddy /usr/bin/caddy

ENV NAIVE_USER=user
ENV NAIVE_PASS=password
ENV UPSTREAM=https://www.bing.com

EXPOSE 8080

COPY <<'EOF' /etc/caddy/Caddyfile
:8080 {
    route {
        forward_proxy {
            basic_auth {$NAIVE_USER} {$NAIVE_PASS}
            hide_ip
            hide_via
            probe_resistance
        }
        reverse_proxy {$UPSTREAM} {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
        }
    }
}
EOF

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
