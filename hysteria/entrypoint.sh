#!/bin/bash
set -e
cat > /etc/hysteria/config.yaml <<EOF
listen: :${UDP_PORT}
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: ${PASSWORD}
masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF
/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml &
echo "Hysteria已启动："
echo "监听端口：${UDP_PORT}"
echo "密码：${PASSWORD}"
echo "客户端连接配置："
echo "hy2://${PASSWORD}@${SERVER_DOMAIN}:${UDP_PORT}?sni=bing.com&insecure=1#H"
wait
