#!/bin/bash
set -euo pipefail

# 定位 nginx 目录
NGINX_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$NGINX_DIR/docker-compose.yml"

echo "========= Nginx 运维管理交互 ========="

# 1. 交互式变量配置
read -p "请输入部署域名 (DOMAIN): " INPUT_DOMAIN
if [ -z "$INPUT_DOMAIN" ]; then echo "错误: 域名不能为空"; exit 1; fi
export DOMAIN=$INPUT_DOMAIN

read -p "请输入监听端口 (PORT, 默认: 443): " INPUT_PORT
export PORT=${INPUT_PORT:-443}

read -p "请输入 WebSocket/gRPC 路径 (默认: xray): " INPUT_W_PATH
export W_PATH=${INPUT_W_PATH:-xray}

# 2. 检查证书 (cert 目录在 nginx/ 下)
CERT_FILE="$NGINX_DIR/cert/fullchain.cer"
KEY_FILE="$NGINX_DIR/cert/$DOMAIN.key"

echo -e "\n[1/2] 检查证书环境..."
if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
    echo "警告: 未在 ./cert 中找到 $DOMAIN 的证书或私钥！"
    read -p "是否强制启动容器? (y/n): " FORCE
    [[ $FORCE != "y" ]] && exit 1
fi

# 3. 确认并启动
echo -e "\n--- 配置确认 ---"
echo "域名: $DOMAIN"
echo "端口: $PORT"
echo "路径: /$W_PATH/"
echo "目录: $NGINX_DIR"
read -p "确认执行? (y/n): " CONFIRM
if [[ $CONFIRM != "y" ]]; then exit 1; fi

echo -e "\n[2/2] 启动 Nginx 服务..."
cd "$NGINX_DIR"

# 使用环境变量启动，Nginx 官方镜像会自动替换 templates 中的变量
if docker compose version &> /dev/null; then
    docker compose up -d
else
    docker-compose up -d
fi

echo -e "\n部署完成！"
echo "------------------------------------------------"
echo "服务状态:"
docker ps --filter "name=nginx"
echo "访问地址: https://$DOMAIN:$PORT/$W_PATH/"
echo "------------------------------------------------"
