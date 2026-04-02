FROM ghcr.io/sagernet/sing-box:latest

ENV PORT=7860
ENV UUID=b34e8834-7a8c-4ecb-94ec-a79ead1dc74d
ENV PATH=/api/v1/stream
ENV HEAD=Sec-WebSocket-Protocol

WORKDIR /var/lib/sing-box

USER root

COPY config.json /etc/sing-box/config.json
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    mkdir -p /var/lib/sing-box && \
    chown -R 1000:1000 /var/lib/sing-box /etc/sing-box

USER 1000

EXPOSE 7860

ENTRYPOINT ["/entrypoint.sh"]
