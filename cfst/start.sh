#!/bin/bash

# 1. 准备初始内容
echo "Scanning WARP IPs on Port ${PORT:-8080}..." > /var/www/html/index.txt

# 2. 后台测速任务
(
while true; do
    ./cfst -f ip.txt -tl 150 -dn 10 -p 0 -o result.csv
    if [ -f "result.csv" ]; then
        sed -n '2,11p' result.csv | awk -F, '{print $1}' > /var/www/html/index.txt
    fi
    sleep 1800
done
) &

# 3. 启动 Caddy 监听 8080
# ${PORT:-8080} 的意思是：如果系统给了端口就用系统的，没给就用 8080
echo "Caddy 起航，目标端口: ${PORT:-8080}"
caddy file-server --listen :${PORT:-8080} --root /var/www/html
