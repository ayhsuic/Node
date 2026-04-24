# syntax=docker/dockerfile:1.4
FROM alpine:3.19 AS builder

RUN apk add --no-cache git gcc musl-dev linux-headers openssl-dev zlib-dev make

WORKDIR /tmp
RUN git clone https://github.com/TelegramMessenger/MTProxy.git && \
    cd MTProxy && \
    make

FROM alpine:3.19

RUN apk add --no-cache openssl su-exec wget

COPY --from=builder /tmp/MTProxy/objs/bin/mtproto-proxy /usr/local/bin/
RUN mkdir -p /etc/mtproxy

ENV PORT=8080 \
    SECRET= \
    DD_SECRET=false \
    WORKERS=1

COPY --chmod=755 <<"EOF" /entrypoint.sh
#!/bin/sh

SECRET=${SECRET:-$(head -c 16 /dev/urandom | xxd -ps)}
[ "$DD_SECRET" = "true" ] && SECRET="dd$SECRET"

wget -q -O /etc/mtproxy/proxy-secret https://core.telegram.org/getProxySecret
wget -q -O /etc/mtproxy/proxy-multi.conf https://core.telegram.org/getProxyConfig

exec su-exec nobody /usr/local/bin/mtproto-proxy \
    -p 8888 \
    -H $PORT \
    -S $SECRET \
    --aes-pwd /etc/mtproxy/proxy-secret /etc/mtproxy/proxy-multi.conf \
    -M $WORKERS \
    -a 0.0.0.0:$PORT
EOF

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]