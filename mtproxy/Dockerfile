# syntax=docker/dockerfile:1.4
# 必须保留上一行以启用高级语法支持

# --- 阶段 1: 编译阶段 ---
FROM ubuntu:22.04 AS builder

# 使用 HEREDOC 语法减少层数和换行符
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

# --- 阶段 2: 运行阶段 ---
FROM ubuntu:22.04

# 安装运行时必要组件
RUN <<EOF
apt-get update
apt-get install -y curl openssl ca-certificates xxd
rm -rf /var/lib/apt/lists/*
EOF

WORKDIR /opt/MTProxy

# 从编译阶段拷贝二进制文件
COPY --from=builder /usr/src/MTProxy/objs/bin/mtproto-proxy .

# 直接在 Dockerfile 中嵌入启动脚本，避免外部文件依赖
COPY <<-"EOF" /opt/MTProxy/entrypoint.sh
#!/bin/bash
set -e

# 1. 自动获取最新的 Telegram 配置（每次启动都会更新）
echo "[1/3] Updating Telegram configuration..."
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

# 2. 密钥逻辑处理
# 如果环境变量 SECRET 为空，则自动生成一个 32 位的
if [ -z "$SECRET" ]; then
    RAW_SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    echo "[2/3] No SECRET provided. Generated: $RAW_SECRET"
else
    # 去掉用户可能误输入的 'dd' 前缀，因为程序内部只接受纯 32 位十六进制
    RAW_SECRET=${SECRET#dd}
    echo "[2/3] Using provided SECRET (normalized): $RAW_SECRET"
fi

# 3. 输出客户端连接信息
USER_SECRET="dd${RAW_SECRET}"
PUBLIC_IP=$(curl -s ifconfig.me || echo "YOUR_SERVER_IP")
echo "------------------------------------------------------"
echo "MTProxy setup complete!"
echo "Server Secret (Internal): $RAW_SECRET"
echo "Client Secret (With DD):  $USER_SECRET"
echo "TG Link: tg://proxy?server=$PUBLIC_IP&port=${PORT:-443}&secret=$USER_SECRET"
echo "------------------------------------------------------"

# 4. 启动程序
# 注意：-S 后面必须是 32 位字符，不能带 dd
echo "[3/3] Starting mtproto-proxy..."
exec ./mtproto-proxy \
    -u nobody \
    -p ${STAT_PORT:-8888} \
    -H ${PORT:-443} \
    -S "$RAW_SECRET" \
    --aes-pwd proxy-secret proxy-multi.conf \
    -M ${WORKERS:-1} \
    ${CUSTOM_ARGS}
EOF

RUN chmod +x /opt/MTProxy/entrypoint.sh

# 默认环境变量配置
ENV PORT=443
ENV STAT_PORT=8888
ENV WORKERS=1

# 暴露端口
EXPOSE ${PORT}
EXPOSE ${STAT_PORT}

ENTRYPOINT ["/opt/MTProxy/entrypoint.sh"]
