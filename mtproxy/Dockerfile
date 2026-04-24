# syntax=docker/dockerfile:1.4
# 使用上方的 syntax 声明以启用 HEREDOC 支持

# --- 第一阶段：编译 ---
FROM ubuntu:22.04 AS builder

RUN <<EOF
apt-get update
apt-get install -y git curl build-essential libssl-dev zlib1g-dev
rm -rf /var/lib/apt/lists/*
EOF

WORKDIR /usr/src/MTProxy
RUN <<EOF
git clone https://github.com/TelegramMessenger/MTProxy .
make
EOF

# --- 第二阶段：运行 ---
FROM ubuntu:22.04

RUN <<EOF
apt-get update
apt-get install -y curl openssl ca-certificates xxd
rm -rf /var/lib/apt/lists/*
EOF

WORKDIR /opt/MTProxy

# 从编译阶段拷贝二进制
COPY --from=builder /usr/src/MTProxy/objs/bin/mtproto-proxy .

# 编写启动脚本：自动生成密钥、更新配置、整合 dd 前缀
COPY <<-"EOF" /opt/MTProxy/entrypoint.sh
#!/bin/bash
set -e

# 1. 自动获取最新的 Telegram 配置
echo "Downloading Telegram secrets..."
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

# 2. 检查是否提供了 SECRET 环境变量，若无则自动生成 32 位随机密钥
if [ -z "$SECRET" ]; then
    RAW_SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    echo "No SECRET provided. Generated random secret: $RAW_SECRET"
    # 强制加上 dd 前缀以启用对抗深度检测的随机填充模式
    FINAL_SECRET="dd${RAW_SECRET}"
else
    # 如果用户提供了密钥但没加 dd，则自动帮其加上
    if [[ $SECRET != dd* ]]; then
        FINAL_SECRET="dd${SECRET}"
    else
        FINAL_SECRET="$SECRET"
    fi
fi

echo "Using Secret: $FINAL_SECRET"
echo "Proxy Link: tg://proxy?server=$(curl -s ifconfig.me)&port=${PORT:-443}&secret=${FINAL_SECRET}"

# 3. 运行服务
exec ./mtproto-proxy \
    -u nobody \
    -p ${STAT_PORT:-8888} \
    -H ${PORT:-443} \
    -S "$FINAL_SECRET" \
    --aes-pwd proxy-secret proxy-multi.conf \
    -M ${WORKERS:-1} \
    ${CUSTOM_ARGS}
EOF

RUN chmod +x /opt/MTProxy/entrypoint.sh

# 默认环境变量
ENV PORT=443
ENV STAT_PORT=8888
ENV WORKERS=1

ENTRYPOINT ["/opt/MTProxy/entrypoint.sh"]
