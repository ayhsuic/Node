FROM caddy:alpine

RUN apk add --no-cache bash wget curl tar

WORKDIR /app

# 下载 cfst
RUN wget -N https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.3.4/cfst_linux_amd64.tar.gz && \
    tar -zxf cfst_linux_amd64.tar.gz && \
    chmod +x cfst

# 预设端口为 8080
ENV PORT=8080

RUN echo "162.159.192.0/24" > ip.txt && \
    echo "162.159.193.0/24" >> ip.txt && \
    echo "162.159.239.0/24" >> ip.txt

RUN mkdir -p /var/www/html
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
