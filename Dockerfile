FROM alpine:3.18

# Устанавливаем Dante (SOCKS) и Python (для веб-сервера)
RUN apk add --no-cache dante-server python3 shadow

# 1. Настраиваем конфигурацию Dante
RUN echo 'logoutput: stderr' > /etc/sockd.conf && \
    echo 'internal: 0.0.0.0 port = 1080' >> /etc/sockd.conf && \
    echo 'external: eth0' >> /etc/sockd.conf && \
    echo 'socksmethod: username' >> /etc/sockd.conf && \
    echo 'user.privileged: root' >> /etc/sockd.conf && \
    echo 'user.unprivileged: sockd' >> /etc/sockd.conf && \
    echo 'client pass { from: 0.0.0.0/0 to: 0.0.0.0/0 }' >> /etc/sockd.conf && \
    echo 'socks pass { from: 0.0.0.0/0 to: 0.0.0.0/0 }' >> /etc/sockd.conf

# 2. Создаем скрипт запуска
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '# Проверка переменных' >> /entrypoint.sh && \
    echo 'if [ -z "$PROXY_USER" ] || [ -z "$PROXY_PASSWORD" ]; then' >> /entrypoint.sh && \
    echo '  echo "Error: PROXY_USER and PROXY_PASSWORD are required"; exit 1;' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo '# Создаем пользователя для прокси' >> /entrypoint.sh && \
    echo 'id -u $PROXY_USER &>/dev/null || useradd -m -s /bin/sh $PROXY_USER' >> /entrypoint.sh && \
    echo "$PROXY_USER:$PROXY_PASSWORD" | chpasswd && \
    echo '# Запускаем фейковый веб-сервер на порту 8000 (фоном)' >> /entrypoint.sh && \
    echo 'mkdir -p /www && echo "Health Check OK" > /www/index.html' >> /entrypoint.sh && \
    echo 'python3 -m http.server 8000 --directory /www &' >> /entrypoint.sh && \
    echo '# Запускаем SOCKS сервер (основной процесс)' >> /entrypoint.sh && \
    echo 'exec sockd -f /etc/sockd.conf' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# 3. Открываем порты
EXPOSE 1080 8000

# 4. Команда старта
CMD ["/entrypoint.sh"]
