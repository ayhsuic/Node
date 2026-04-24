# syntax=docker/dockerfile:1.4
FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN git clone https://github.com/TelegramMessenger/MTProxy.git

WORKDIR /tmp/MTProxy
RUN make

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openssl \
    wget \
    && rm -rf /var/lib/apt/lists/*

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

exec /usr/local/bin/mtproto-proxy \
    -p 8888 \
    -H $PORT \
    -S $SECRET \
    --aes-pwd /etc/mtproxy/proxy-secret /etc/mtproxy/proxy-multi.conf \
    -M $WORKERS \
    -a 0.0.0.0:$PORT
EOF

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]