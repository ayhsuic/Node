FROM alpine:latest

ENV UDP_PORT=80
ENV PASSWORD=your-uuid-password
ENV DOMAIN=*.example.com
ENV EMAIL=your@email.address
ENV CF_API_TOKEN=your_cloudflare_api_token

RUN apk update && \
    apk add --no-cache curl wget ca-certificates bash && \
    mkdir -p /etc/hysteria /var/lib/hysteria/acme

RUN wget -q -O /usr/local/bin/hysteria https://download.hysteria.network/app/latest/hysteria-linux-amd64 && \
    chmod +x /usr/local/bin/hysteria

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE ${UDP_PORT}/udp

VOLUME /var/lib/hysteria/acme

ENTRYPOINT ["/entrypoint.sh"]
