#!/bin/bash
set -e

cat > /etc/hysteria/config.yaml <<EOF
listen: :${UDP_PORT}

acme:
  domains:
    - "${DOMAIN}"
  email: "${EMAIL}"
  type: dns
  dns:
    name: cloudflare
    config:
      cloudflare_api_token: "${CF_API_TOKEN}"
  dir: /var/lib/hysteria/acme

auth:
  type: password
  password: "${PASSWORD}"

masquerade:
  type: proxy
  proxy:
    url: "${DOMAIN}"
    rewriteHost: true
EOF

/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml &

echo "-----------------------------------------------------"
echo "Hysteria v2 正在启动..."
echo "模式：ACME DNS-01 (Cloudflare)"
echo "域名：${DOMAIN}"
echo "端口：${UDP_PORT} (UDP)"
echo "密码：${PASSWORD}"
echo "-----------------------------------------------------"
echo "提示：首次运行需要 10-30 秒完成 DNS 验证并获取证书。"
echo "客户端连接串 (正式证书无需 insecure):"
echo "hy2://${PASSWORD}@${DOMAIN}:${UDP_PORT}?sni=${DOMAIN}#Hysteria"
echo "-----------------------------------------------------"

wait
