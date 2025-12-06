FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends dante-server privoxy ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Конфиг Dante и Privoxy
COPY danted.conf /etc/danted.conf
COPY privoxy.config /etc/privoxy/config

# Переменные для логина/пароля SOCKS5
ENV PROXY_USER=denis \
    PROXY_PASSWORD=changeme

# Скрипт запуска
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1080 8118

ENTRYPOINT ["/entrypoint.sh"]
