
#!/bin/bash
set -euo pipefail

# 获取当前脚本所在目录
XRAY_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$XRAY_DIR/config"

echo "========= Xray 配置管理 ========="

# 1. 交互配置
read -p "请输入 Port (默认: 443): " INPUT_PORT
PORT=${INPUT_PORT:-443}

read -p "请输入 UUID (回车自动生成): " INPUT_UUID
UUID=${INPUT_UUID:-$(cat /proc/sys/kernel/random/uuid)}

read -p "请输入 REALITY Dest (默认: yahoo.com:443): " INPUT_DEST
DEST=${INPUT_DEST:-yahoo.com:443}

read -p "请输入 REALITY Server Names (默认: yahoo.com, 输入 none 留空): " INPUT_SERVER_NAME
if [[ "$INPUT_SERVER_NAME" == "none" ]]; then
    SERVER_NAME_JSON="[]"
    SERVER_NAME_VAL="none (empty)"
else
    SERVER_NAME=${INPUT_SERVER_NAME:-yahoo.com}
    SERVER_NAME_JSON="[\"$SERVER_NAME\"]"
    SERVER_NAME_VAL=$SERVER_NAME
fi

echo "[1/3] 正在准备 REALITY 密钥生成器..."
docker pull teddysun/xray:latest > /dev/null 2>&1

# 生成密钥
KEYS=$(docker run --rm teddysun/xray xray x25519 2>/dev/null)

if [[ -z "$KEYS" ]]; then
    echo "❌ 错误: 密钥生成失败。请手动检查 docker run teddysun/xray xray x25519"
    exit 1
fi

# 适配您的 Xray 输出格式
PRIVATE_KEY=$(echo "$KEYS" | grep "PrivateKey:" | cut -d: -f2 | xargs || echo "")
PUBLIC_KEY=$(echo "$KEYS" | grep "Password:" | cut -d: -f2 | xargs || echo "")

if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
    echo "❌ 错误: 密钥解析失败。Docker 输出格式可能已变更。"
    echo "原始输出内容:"
    echo "$KEYS"
    exit 1
fi



echo -e "\n--- 配置确认 ---"
echo "Port: $PORT"
echo "UUID: $UUID"
echo "Dest: $DEST"
echo "Server Name: $SERVER_NAME_VAL"
echo "Public Key: $PUBLIC_KEY"
read -p "确认写入配置并启动? (Y/n): " CONFIRM
[[ "${CONFIRM,,}" == "n" ]] && exit 1

# 2. 动态替换配置块中的变量
echo "[2/3] 正在更新配置文件..."
CONFIG_TEMPLATE="$CONFIG_DIR/config.json.template"
CONFIG_FILE="$CONFIG_DIR/config.json"

if [ -f "$CONFIG_TEMPLATE" ]; then
    # 每次从模板生成，防止重复运行导致占位符消失
    cp "$CONFIG_TEMPLATE" "$CONFIG_FILE"
    
    sed -i "s/\${PORT}/$PORT/g" "$CONFIG_FILE"
    sed -i "s/\${UUID}/$UUID/g" "$CONFIG_FILE"
    sed -i "s/\${DEST}/$DEST/g" "$CONFIG_FILE"
    sed -i "s/\${SERVER_NAMES_ARRAY}/$SERVER_NAME_JSON/g" "$CONFIG_FILE"
    sed -i "s|\${PRIVATE_KEY}|$PRIVATE_KEY|g" "$CONFIG_FILE"
else
    echo "❌ 警告: 未找到配置文件模板 $CONFIG_TEMPLATE"
    # 如果不存在模板，则尝试直接修改原文件
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "s/\${PORT}/$PORT/g" "$CONFIG_FILE"
        sed -i "s/\${UUID}/$UUID/g" "$CONFIG_FILE"
        sed -i "s/\${DEST}/$DEST/g" "$CONFIG_FILE"
        sed -i "s/\${SERVER_NAMES_ARRAY}/$SERVER_NAME_JSON/g" "$CONFIG_FILE"
        sed -i "s|\${PRIVATE_KEY}|$PRIVATE_KEY|g" "$CONFIG_FILE"
    fi
fi



# 3. 启动服务
echo "[3/3] 启动容器..."
cd "$XRAY_DIR"
docker compose up -d

echo -e "\n服务启动完成！"
echo "Port: $PORT"
echo "UUID: $UUID"
echo "Public Key: $PUBLIC_KEY"
echo "Dest: $DEST"
echo "Server Name: $SERVER_NAME"
