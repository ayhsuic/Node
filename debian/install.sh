#!/bin/bash
set -euo pipefail

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "================================================"
echo "🚀 欢迎使用 Xray-REALITY 一键安装工具"
echo "================================================"

# 1. 系统初始化 (安装 Docker 等基础环境)
if [ -f "$PROJECT_ROOT/init/init.sh" ]; then
    echo -e "\n[1/2] 正在执行系统初始化 (init.sh)..."
    chmod +x "$PROJECT_ROOT/init/init.sh"
    sudo "$PROJECT_ROOT/init/init.sh"
else
    echo -e "\n[!] 未发现 init.sh，跳过系统初始化。"
fi

# 2. DDNS 配置 (可选)
echo -e "\n[2/3] 是否需要配置 DDNS? (y/N, 默认跳过): "
read -p "> " CONFIRM_DDNS
if [[ "${CONFIRM_DDNS,,}" == "y" ]]; then
    echo "请选择使用的脚本:"
    echo "1) ddns.sh (服务版 - 持续同步)"
    echo "2) cloudflare-ddns.sh (API版 - 一次性同步)"
    read -p "请输入选项 [1-2, 默认1]: " DDNS_CHOICE
    DDNS_CHOICE=${DDNS_CHOICE:-1}

    if [ "$DDNS_CHOICE" == "2" ]; then
        chmod +x "$PROJECT_ROOT/ddns/cloudflare-ddns.sh"
        "$PROJECT_ROOT/ddns/cloudflare-ddns.sh"
    else
        chmod +x "$PROJECT_ROOT/ddns/ddns.sh"
        sudo "$PROJECT_ROOT/ddns/ddns.sh"
    fi
else
    echo "跳过 DDNS 配置。"
fi

# 3. 交互配置并启动 Xray
echo -e "\n[3/3] 正在配置并启动 Xray 服务 (REALITY)..."
if [ -f "$PROJECT_ROOT/xray/xray.sh" ]; then
    chmod +x "$PROJECT_ROOT/xray/xray.sh"
    "$PROJECT_ROOT/xray/xray.sh"
else
    echo -e "\n[❌] 错误: 未找到 $PROJECT_ROOT/xray/xray.sh"
    exit 1
fi

echo -e "\n================================================"
echo "✅ REALITY 服务已部署完成！"
echo "================================================"
echo "当前容器运行状态:"
docker ps
echo "================================================"
