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
    xxd \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/MTProxy/objs/bin/mtproto-proxy /usr/local/bin/
RUN mkdir -p /etc/mtproxy

ENV PORT=8080 \
    SECRET="" \
    DD_SECRET=false \
    WORKERS=1

COPY --chmod=755 <<"EOF" /entrypoint.sh
#!/bin/sh

# 生成或使用提供的 SECRET
if [ -z "$SECRET" ]; then
    SECRET=$(head -c 16 /dev/urandom | xxd -ps | tr -d '\n')
    echo "Generated secret: $SECRET"
else
    echo "Using provided secret: $SECRET"
fi

# 验证 secret 长度
if [ ${#SECRET} -ne 32 ]; then
    echo "ERROR: SECRET must be exactly 32 hex characters, got ${#SECRET}: $SECRET"
    exit 1
fi

# 启用随机填充
if [ "$DD_SECRET" = "true" ]; then
    SECRET="dd$SECRET"
    echo "Random padding enabled, secret: $SECRET"
fi

# 首次获取配置（后台持续更新）
wget -q -O /etc/mtproxy/proxy-secret https://core.telegram.org/getProxySecret
wget -q -O /etc/mtproxy/proxy-multi.conf https://core.telegram.org/getProxyConfig

# 后台每天更新配置
(
    while true; do
        sleep 86400
        wget -q -O /etc/mtproxy/proxy-secret https://core.telegram.org/getProxySecret
        wget -q -O /etc/mtproxy/proxy-multi.conf https://core.telegram.org/getProxyConfig
    done
) &

# 运行代理
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