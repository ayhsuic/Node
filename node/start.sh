#!/bin/sh

# 后台启动 wireproxy 建立 WARP 到 SOCKS5 的隧道
/usr/local/bin/wireproxy -c wireproxy.conf &

# 给它 3 秒钟时间连接 Cloudflare
sleep 3

# 启动你的主程序
node index.js
