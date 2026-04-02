#!/bin/bash
set -euo pipefail

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "================================================"
echo "🚀 欢迎使用项目一键部署工具"
echo "================================================"

# 1. 系统初始化
echo -e "\n[1/5] 正在执行系统初始化 (init.sh)..."
chmod +x "$PROJECT_ROOT/init/init.sh"
sudo "$PROJECT_ROOT/init/init.sh"

# 2. DDNS 配置 (可选)
echo -e "\n[2/5] 是否需要配置 DDNS? (y/N, 默认跳过): "
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

# 3. 申请 TLS 证书
# 注意：采用 DNS 验证无需先启动 Nginx，直接申请即可
echo -e "\n[3/5] 正在执行证书申请 (cert.sh)..."
chmod +x "$PROJECT_ROOT/nginx/cert/cert.sh"
"$PROJECT_ROOT/nginx/cert/cert.sh"

# 4. 启动 Xray 服务
echo -e "\n[4/5] 正在启动 Xray 服务 (xray.sh)..."
chmod +x "$PROJECT_ROOT/xray/xray.sh"
"$PROJECT_ROOT/xray/xray.sh"

# 5. 启动 Nginx 服务
echo -e "\n[5/5] 正在启动 Nginx 服务 (nginx.sh)..."
chmod +x "$PROJECT_ROOT/nginx/nginx.sh"
"$PROJECT_ROOT/nginx/nginx.sh"

echo -e "\n================================================"
echo "✅ 所有组件已部署完成！"
echo "================================================"
echo "当前容器运行状态:"
docker ps
echo "------------------------------------------------"
echo "温馨提示:"
echo "1. 请检查 Nginx 配置文件中的域名与证书路径是否匹配。"
echo "2. 若 Xray 无法连接，请检查 Unix Socket (/dev/shm/xrxh.socket) 是否创建。"
echo "================================================"
