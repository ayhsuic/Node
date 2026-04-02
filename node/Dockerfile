FROM node:lts

WORKDIR /tmp

# 安装 wget
RUN apt-get update && apt-get install -y wget curl

# 下载并安装 wireproxy (完全在用户态运行，无需特权模式)
RUN wget -O wireproxy.tar.gz https://github.com/pufferffish/wireproxy/releases/download/v1.0.7/wireproxy_linux_amd64.tar.gz \
    && tar -xzf wireproxy.tar.gz -C /usr/local/bin/ \
    && rm wireproxy.tar.gz \
    && chmod +x /usr/local/bin/wireproxy

COPY package.json ./
RUN npm install

# 拷贝所有配置文件和代码
COPY index.js index.html wireproxy.conf start.sh ./
RUN chmod +x start.sh

EXPOSE 8000

# 启动包装脚本
CMD ["./start.sh"]
