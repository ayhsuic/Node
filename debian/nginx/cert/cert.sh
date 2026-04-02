#!/bin/bash
set -euo pipefail

# 获取当前脚本所在目录 (即 nginx/cert)
DEFAULT_CERT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========= ACME 证书申请 (DNS 验证 - Token版) ========="

# 1. 域名配置
read -p "请输入你的域名 (例如 example.com): " INPUT_DOMAIN
if [ -z "$INPUT_DOMAIN" ]; then
    echo "错误: 域名不能为空！"
    exit 1
fi
DOMAIN=$INPUT_DOMAIN

# 2. 邮箱配置
read -p "请输入联系邮箱 (默认: my@example.com): " INPUT_EMAIL
EMAIL=${INPUT_EMAIL:-my@example.com}

# 3. DNS API 配置 (仅使用 API Token)
echo -e "\n--- DNS API 配置 (Cloudflare Token) ---"
read -p "请输入 Cloudflare API Token: " CF_Token

if [[ -z "$CF_Token" ]]; then
    echo "错误: Cloudflare API Token 不能为空！"
    exit 1
fi

# 核心修正：仅导出 CF_Token，务必清除旧的 Key 变量防止冲突
export CF_Token="$CF_Token"

# 4. 证书安装目录
read -p "请输入证书安装目录 (默认: $DEFAULT_CERT_DIR): " INPUT_CERT_DIR
CERT_DIR=${INPUT_CERT_DIR:-$DEFAULT_CERT_DIR}

echo -e "\n--- 当前配置确认 ---"
echo "域名: $DOMAIN"
echo "邮箱: $EMAIL"
echo "方式: DNS 验证 (Cloudflare API Token)"
echo "安装目录: $CERT_DIR"
read -p "确认开始执行? (Y/n): " CONFIRM
[[ "${CONFIRM,,}" == "n" ]] && exit 1

# --- 执行阶段 ---

echo "[1/5] 安装 acme.sh..."
if ! command -v acme.sh &> /dev/null; then
    curl https://get.acme.sh | sh -s email=$EMAIL
else
    echo "acme.sh 已经安装。"
fi
export PATH="$HOME/.acme.sh:$PATH"

echo "[2/5] 开启自动更新..."
acme.sh --upgrade --auto-upgrade

echo "[3/5] 设置默认 CA (Let's Encrypt)..."
acme.sh --set-default-ca --server letsencrypt

echo "[4/5] 申请 ECC 证书 (DNS 方式)..."
# acme.sh 会自动检测到 CF_Token 环境参数并调用对应的 API 逻辑
acme.sh --issue --dns dns_cf -d "$DOMAIN" --keylength ec-256 --force

echo "[5/5] 安装证书到指定目录..."
mkdir -p "$CERT_DIR"
acme.sh --install-cert -d "$DOMAIN" \
    --cert-file      "$CERT_DIR/$DOMAIN.cer" \
    --key-file       "$CERT_DIR/$DOMAIN.key" \
    --fullchain-file "$CERT_DIR/fullchain.cer" \
    --ecc
chmod 644 "$CERT_DIR"/*.key

echo -e "\n--- 证书安装完成 ---"
echo "证书位置: $CERT_DIR/fullchain.cer"
echo "密钥位置: $CERT_DIR/$DOMAIN.key"
