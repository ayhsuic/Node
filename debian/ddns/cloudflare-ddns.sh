#!/bin/bash
set -euo pipefail

# 内部变量
CF_API="https://api.cloudflare.com/client/v4"
TOKEN_FILE="/etc/cloudflare-ddns/token"

echo "========= Cloudflare API DDNS 交互配置 ========="

# 1. 检查依赖
echo "[1/5] 检查系统依赖 (curl, jq)..."
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "正在安装 $cmd..."
        apt-get update && apt-get install $cmd -y
    fi
done

# 2. 交互式获取变量
read -p "请输入 DNS 记录名称 (例如 sub.example.com): " RECORD_NAME
if [ -z "$RECORD_NAME" ]; then echo "错误: 域名不能为空"; exit 1; fi

# 尝试从文件读取 Token，否则交互输入
if [ -r "$TOKEN_FILE" ]; then
    CF_TOKEN=$(cat "$TOKEN_FILE")
    echo "从 $TOKEN_FILE 加载了现有的 Token。"
else
    read -p "请输入 Cloudflare API Token: " CF_TOKEN
    if [ -z "$CF_TOKEN" ]; then echo "错误: Token 不能为空"; exit 1; fi
fi

echo -e "\n--- 配置确认 ---"
echo "域名: $RECORD_NAME"
echo "Token: ${CF_TOKEN:0:4}****${CF_TOKEN: -4}"
read -p "确认开始执行同步? (Y/n): " CONFIRM
if [[ "${CONFIRM,,}" == "n" ]]; then exit 1; fi

# 3. 准备工作环境
mkdir -p "/etc/cloudflare-ddns"
echo "$CF_TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

# 4. 执行核心同步逻辑
echo -e "\n[2/5] 获取当前公网 IP..."
PUBLIC_IP=$(curl -fsS https://api.ipify.org)
echo "当前公网 IP: $PUBLIC_IP"

echo "[3/5] 自动检测区域 (Zone ID)..."
ZONES_JSON=$(curl -fsS -X GET "$CF_API/zones" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json")

if [[ "$(echo "$ZONES_JSON" | jq -r '.success')" != "true" ]]; then
    echo "错误: 无法获取 Zone 信息，请检查 Token 权限。" >&2
    exit 1
fi

# 改进的匹配逻辑：确保是精确匹配域名或其子域名
ZONE_ID=$(echo "$ZONES_JSON" | jq -r --arg record "$RECORD_NAME" '.result[] | select($record == .name or ($record | endswith("." + .name))) | .id' | head -n 1)
if [[ -z "$ZONE_ID" ]]; then
  echo "错误: 找不到持有 $RECORD_NAME 的 Zone。" >&2
  exit 1
fi

echo "[4/5] 查询现有的 DNS 记录..."
RECORD_JSON=$(curl -fsS -X GET "$CF_API/zones/$ZONE_ID/dns_records?name=$RECORD_NAME&type=A" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json")

RECORD_ID=$(echo "$RECORD_JSON" | jq -r '.result[0].id // empty')
DNS_IP=$(echo "$RECORD_JSON" | jq -r '.result[0].content // empty')

echo "[5/5] 更新/创建 DNS 记录..."
if [[ -n "$RECORD_ID" ]]; then
  if [[ "$PUBLIC_IP" == "$DNS_IP" ]]; then
    echo ">>> IP 未改变 ($PUBLIC_IP)，无需更新。"
  else
    echo ">>> IP 已变动: $DNS_IP -> $PUBLIC_IP，正在更新..."
    PAYLOAD=$(jq -n --arg t "A" --arg n "$RECORD_NAME" --arg c "$PUBLIC_IP" '{type:$t,name:$n,content:$c,ttl:120,proxied:false}')
    curl -fsS -X PUT "$CF_API/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $CF_TOKEN" \
      -H "Content-Type: application/json" \
      --data "$PAYLOAD"
    echo -e "\n>>> 更新尝试完成。"
  fi
else
  echo ">>> 未找到 A 记录，正在创建 $RECORD_NAME -> $PUBLIC_IP..."
  PAYLOAD=$(jq -n --arg t "A" --arg n "$RECORD_NAME" --arg c "$PUBLIC_IP" '{type:$t,name:$n,content:$c,ttl:120,proxied:false}')
  curl -fsS -X POST "$CF_API/zones/$ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    --data "$PAYLOAD"
  echo -e "\n>>> 创建尝试完成。"
fi


echo -e "\nCloudflare API 同步任务完成！"
