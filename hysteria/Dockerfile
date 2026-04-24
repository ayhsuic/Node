FROM alpine:latest

ENV SERVER_DOMAIN=example.clawcloudrun.com
ENV UDP_PORT=80
ENV PASSWORD=your-uuid-password

RUN apk update && \
    apk add --no-cache curl wget openssl bash ca-certificates && \
    mkdir -p /etc/hysteria

RUN wget -q -O /usr/local/bin/hysteria https://download.hysteria.network/app/latest/hysteria-linux-amd64 && \
    chmod +x /usr/local/bin/hysteria

RUN openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
    -keyout /etc/hysteria/server.key \
    -out /etc/hysteria/server.crt \
    -subj "/CN=bing.com" -days 36500

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE ${UDP_PORT}/udp

ENTRYPOINT ["/entrypoint.sh"]